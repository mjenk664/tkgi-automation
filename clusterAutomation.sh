set -e
set -u
set -o pipefail

run() {
  echo >&2 "## running: ${*}" ; "${@}"
}

yqx() {
    local -r e=$1
    local -r f=$2
    yq e "$e" - < $f
}

cluster_config() {
    local -r cluster=$1
    local -r cluster_dir=$2
    echo "${cluster_dir}/${cluster}/tkgi.yaml"
}

login() {
    local -r tkgi_api=$1
    local -r tkgi_username=$2
    local -r tkgi_password=$3
    tkgi login -a "${tkgi_api}" -u "${tkgi_username}" -p "${tkgi_password}" -k
}

cluster_data() {
    local -r cluster=$1
    tkgi cluster $cluster --json
}

cluster_details() {
    local -r cluster=$1
    tkgi cluster $cluster --json --details
}

delete_cluster() {
    local -r cluster=$1

    cluster_exists=$(tkgi clusters --json | jq '.[] | .name' -rc)

    if [[ "$(echo "$cluster_exists" | grep "$cluster")" == "" ]]; then
      echo -e "Error: Cannot delete cluster as it does not exist: $cluster"
      exit 1
    else
      echo "Deleting cluster"
      tkgi delete-cluster \
        $cluster \
        --non-interactive \
        --wait
    fi
}

existing_num_nodes() {
    local -r c=${1}
    echo "${c}" | jq '.parameters.kubernetes_worker_instances' -r
}

external_hostname() {
    local -r cc=$1

    if [[ "$(cat $cc | grep -e "external_hostname")" == "" ]]; then
       # Error out if External Hostname is not defined in config
       echo "No External Hostname defined in $cc...Aborting!"
       echo "Please define an External Hostname in $cc"
       exit 1
    else
       # return External Hostname from config
       yqx '.external_hostname' $cc
    fi
}

plan() {
    local -r cc=$1

    if [[ "$(cat $cc | grep -e "plan")" == "" ]]; then
       # Error out if Plan is not defined in config
       echo "No Plan defined in $cc...Aborting!"
       echo "Please define a Plan in $cc"
       exit 1
    else
       # return NP name from config
       yqx '.plan' "$cc"
    fi
}

network_profile() {
    local -r cc=$1

    if [[ "$(cat $cc | grep -e "network_profile")" == "" ]]; then
       # Error out if NP is not defined in config
       echo "No Network Profile defined in $cc...Aborting!"
       echo "Please define a Network Profile in $cc"
       exit 1
    else
       # return NP name from config
       np_check=$(yqx '.network_profile' "$cc")
       echo "--network-profile $np_check"
    fi
}

kubernetes_profile() {
    local -r cc=$1

    if [[ "$(cat $cc | grep -e "kubernetes_profile")" == "" ]]; then
       # Error out if KP is not defined in config
       echo "No Kubernetes Profile defined in $cc...Aborting!"
       echo "Please define a Kubernetes Profile in $cc"
       exit 1
    else
       # return KP name from config
       kp_check=$(yqx '.kubernetes_profile' "$cc")
       echo "--kubernetes-profile $kp_check"
    fi
}

check_kubernetes_profile_exists() {
    local -r cluster=$1
    local -r cluster_dir=$2
    local -r cc=$(cluster_config $cluster $cluster_dir)
    local -r kp_name=$(yqx '.kubernetes_profile' $cc)

    # check if KP has been created in TKGI
    kp_exists=$(tkgi kubernetes-profiles --json | jq '.[] | .name' -rc)

    # search in the common directory for the profile name
    if [[ "$(echo "$kp_exists" | grep "$kp_name")" == "" ]]; then
      echo -e "Error - Kubernetes Profile: $kp_name does not exist in TKGI"
      echo "Attemping to create the Kubernetes Profile: $kp_name"
      echo "Searching in profile in common directory"
      kp_file_path=$(find ../common/ -name *$kp_name*)
      tkgi create-kubernetes-profile "${kp_file_path}"
    else
      echo "Kubernetes Profile: $kp_name found in TKGI!"
    fi
}

compute_profile() {
    local -r cc=$1

    if [[ "$(cat $cc | grep -e "compute_profile")" != "" ]]; then
       # return CP name from config
       cp_check=$(yqx '.compute_profile' "$cc")
       echo "--compute-profile $cp_check"
    fi
}

check_compute_profile_exists() {
    local -r cluster=$1
    local -r cluster_dir=$2
    local -r cc=$(cluster_config $cluster $cluster_dir)
    local -r cp_name=$(yqx '.compute_profile' $cc)

    # check if CP has been created in TKGI
    cp_exists=$(tkgi compute-profiles --json | jq '.[] | .name' -rc)

    # search in the common directory for the profile name
    if [[ "$(echo "$cp_exists" | grep "$cp_name")" == "" ]]; then
      echo -e "Error - Compute Profile: $cp_name does not exist in TKGI"
      echo "Attemping to create the Compute Profile: $cp_name"
      echo "Searching in profile in $cluster_dir directory"
      cp_file_path=$(find $cluster_dir -name *$cp_name*)
      tkgi create-compute-profile "${cp_file_path}"
    else
      echo "Compute Profile: $cp_name found in TKGI!"
    fi
}

upgrade_cluster() {
  local -r cluster=$1
  local -r cluster_dir=$2
  local -r cc=$(cluster_config $cluster $cluster_dir)
  echo "cluster_config = ${cc}"

  # run upgrade-cluster
  echo "Running tkgi upgrade-cluster $cluster"
  run \
     tkgi \
     upgrade-cluster $cluster \
     --non-interactive
}

update_cluster() {
  local -r cluster=$1
  local -r cluster_dir=$2
  local -r cc=$(cluster_config $cluster $cluster_dir)
  echo "cluster_config = ${cc}"
  local -r tnn=$(yqx .num_nodes $cc)
  local -r c=$(cluster_data $cluster)
  local -r ehn=$(external_hostname $cc)
  local -r p=$(plan $cc)
  local -r np=$(network_profile $cc)
  local -r kp=$(kubernetes_profile $cc)
  local -r cp=$(compute_profile $cc)

  if [ ! -z "$c" ];
  then
      # if a compute profile exists, then
      # update cluster w/ --compute-profile
      if [ ! -z "$cp" ];
      then
        echo update $cluster \
             with external hostname $ehn \
             using plan $p \
             and profile flags... \
             $np \
             $kp \
             $cp
        run \
            tkgi \
            update-cluster $cluster \
            --external-hostname $ehn \
            --plan $p \
            --num-nodes $tnn \
            $np \
            $kp \
            $cp \
            --wait
      else
        echo updating $cluster \
             with external hostname $ehn \
             using plan $p \
             and profile flags... \
             $np \
             $kp
        run \
            tkgi \
            update-cluster $cluster \
            --external-hostname $ehn \
            --plan $p \
            --num-nodes $tnn \
            $np \
            $kp \
            --wait
      fi
  fi

  echo "Cluster Details: $(cluster_details $cluster)"
}

converge_cluster() {
  local -r cluster=$1
  local -r cluster_dir=$2
  local -r cc=$(cluster_config $cluster $cluster_dir)
  echo "cluster_config = ${cc}"
  local -r tnn=$(yqx .num_nodes $cc)
  local -r c=$(cluster_data $cluster)
  local -r ehn=$(external_hostname $cc)
  local -r p=$(plan $cc)
  local -r np=$(network_profile $cc)
  local -r kp=$(kubernetes_profile $cc)
  local -r cp=$(compute_profile $cc)

  if [ ! -z "$c" ];
  then
      local -r enn=$(existing_num_nodes "${c}")

      if [ ! -z "$cp" ];
      then
        echo "Skip resize for cluster with compute-profile"
        # TODO: add logic for resizing a cluster with compute profile
      else
         if [ "$tnn" != "$enn" ];
         then
           echo "scaling $cluster from $enn to $tnn"
           run \
              tkgi \
              resize $cluster \
              --non-interactive \
              --num-nodes $tnn \
              --wait
         else
           echo "cluster $cluster already at target node count ($enn)"
         fi
      fi
  else
      # if a compute profile exists, then
      # create cluster w/ --compute-profile
      if [ ! -z "$cp" ];
      then
        echo constructing $cluster \
             with external hostname $ehn \
             using plan $p \
             and profile flags... \
             $np \
             $kp \
             $cp
        run \
            tkgi \
            create-cluster $cluster \
            --external-hostname $ehn \
            --plan $p \
            --num-nodes $tnn \
            $np \
            $kp \
            $cp \
            --wait
      else
        echo constructing $cluster \
             with external hostname $ehn \
             using plan $p \
             and profile flags... \
             $np \
             $kp
        run \
            tkgi \
            create-cluster $cluster \
            --external-hostname $ehn \
            --plan $p \
            --num-nodes $tnn \
            $np \
            $kp \
            --wait
      fi
  fi

  echo "Cluster Details: $(cluster_details $cluster)"

  # run tkgi get-credentials "$cluster"
  # kubectl config set-context "$cluster"

  # echo "## generating & applying kustomizatons from '${cluster_dir}'"
  # kustomize build --enable_alpha_plugins "${cluster_dir}" \
  #     | kubectl apply -f -
}

converge() {
  local -r cluster_dir=$1
  echo iterating through cluster definitions in $cluster_dir...
  local cluster
  for dir in ${cluster_dir}/*; do
      if [ -d "$dir" ];
      then
          cluster=$(basename "${dir}")
          echo converging cluster $cluster...
          run converge_cluster $cluster $cluster_dir
      else
          echo skipping $dir...
      fi
  done
  echo done
}

# upgrade all clusters in parallel
upgrade_all_clusters() {
  local -r cluster_dir=$1

  echo iterating through cluster definitions in $cluster_dir...
  local cluster

  for dir in ${cluster_dir}/*; do
      if [ -d "$dir" ];
      then
          cluster=$(basename "${dir}")
          echo upgrading cluster $cluster...
          run upgrade_cluster $cluster $cluster_dir
      else
          echo skipping $dir...
      fi
  done
  echo done
}