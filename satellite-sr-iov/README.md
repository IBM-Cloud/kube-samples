# SR-IOV on IBM Cloud Satellite

Single Root I/O Virtualization (SR-IOV) is a specification that allows pods inside the cluster to share PCI resources which can improve performance. The OpenShift SR-IOV operator divides a supported network device into multiple virtual functions. Once the operator is enabled, pods inside the cluster can use the SR-IOV network.

## Enable the OpenShift SR-IOV operator on IBM Cloud Satellite

You can run the OpenShift SR-IOV operator on your OpenShift on IBM Cloud cluster that runs on IBM Cloud Satellite. The hosts that you add to your OpenShift cluster in Satellite must meet the following requirements: 
* [All host musts be set up with a supported Network Interface Card (NIC) model](https://docs.openshift.com/container-platform/4.6/networking/hardware_networks/about-sriov.html#supported-devices_about-sriov)
* [All hosts must meet the general host requirements for IBM Cloud Satellite](https://cloud.ibm.com/docs/satellite?topic=satellite-host-reqs)
* All hosts must be bare metal servers.

If the hosts for your cluster meet these requirements, then follow the OpenShift SR-IOV operator [installation guide](https://docs.openshift.com/container-platform/4.6/networking/hardware_networks/installing-sriov-operator.html). If you do not have any hosts that meet these requirements, you can follow the instructions on this page to test out the SR-IOV Operator on IBM Cloud bare metal servers.

## Test out the SR-IOV Operator on IBM Cloud infrastructure.

You can try out the SR-IOV operator in IBM Cloud Satellite by using IBM Cloud bare metal servers. 

**Note**: Satellite is an extension of IBM Cloud into other infrastructure providers. As such, adding IBM Cloud infrastructure hosts to Satellite is supported only for testing, demo, or proof of concept purposes. For production workloads in your Satellite location, use on-premises, edge, or other cloud provider hosts.

1. Create an [IBM Cloud Satellite Location](https://cloud.ibm.com/docs/satellite?topic=satellite-locations#location-create)

2. Attach [hosts for the control plane](https://cloud.ibm.com/docs/satellite?topic=satellite-getting-started#attach-hosts-to-location) to the location.
    * Control plane hosts can be virtual servers, but hosts for your OpenShift cluster must be classic bare metal servers.

3. Attach [hosts for the OpenShift cluster](https://cloud.ibm.com/docs/satellite?topic=satellite-hosts#attach-hosts) to the location.
    * OpenShift cluster hosts must be bare metal servers.
    * Select at least 4 CPU and 32 GB RAM.
    * In the network interface menu, select "none" for port redundancy. This will create unbonded NICs on the server. The SR-IOV operator is supported on specific bonded NICs. For testing purposes this example will use unbonded NICs.

4. [Create an OpenShift 4.6 cluster](https://cloud.ibm.com/docs/satellite?topic=openshift-satellite-clusters).

5. When the cluster is deployed, set kernel parameters on each bare metal server.
   
   For each bare metal server, set the following parameters. Hosts with an older BIOS can require updated kernel boot parameters.
    1. Run oc debug to get access to the node.

        To get a list of nodes, run `oc get nodes`.

        `oc debug node/<node-ip>`

    2. Run `chroot` to run host binaries.

        `chroot /host`

    3. Edit the grub settings and add the `pci=realloc pci=assign-busses` options to `GRUB_CMDLINE_LINUX`.

        `vi /etc/default/grub`

        After you edit the file the output will look like:

        `cat /etc/default/grub`

        ```
        GRUB_TIMEOUT=5
        GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
        GRUB_DEFAULT=saved
        GRUB_DISABLE_SUBMENU=true
        GRUB_TERMINAL_OUTPUT="console"
        GRUB_CMDLINE_LINUX="crashkernel=auto spectre_v2=retpoline nomodeset biosdevname=0 net.ifnames=0 pci=realloc pci=assign-busses"
        GRUB_DISABLE_RECOVERY="true"
        ```

    4. Generate the grub config.

        `grub2-mkconfig > /boot/grub2/grub.cfg`

    5. Reboot the bare metal server.

        `reboot`

    6. Test that the host can create virtual functions.

        * `modprobe -r igb`
        * `modprobe igb`

    7. Set the number of virtual functions.
        
        `echo 32 > /sys/class/net/int0/device/sriov_numvfs`

    8. List virtual functions.
        If the set up was successful, you see a list of virtual functions.

        `lspci | grep "Virtual Function"`

        ```
        03:0b.6 Ethernet controller: Intel Corporation Ethernet Virtual Function 700 Series (rev 02)
        03:0d.3 Ethernet controller: Intel Corporation Ethernet Virtual Function 700 Series (rev 02)
        03:0d.4 Ethernet controller: Intel Corporation Ethernet Virtual Function 700 Series (rev 02)
        03:0d.5 Ethernet controller: Intel Corporation Ethernet Virtual Function 700 Series (rev 02)
        03:0d.6 Ethernet controller: Intel Corporation Ethernet Virtual Function 700 Series (rev 02)
        03:0d.7 Ethernet controller: Intel Corporation Ethernet Virtual Function 700 Series (rev 02)
        ...
        ```
6. Label the worker nodes where you enabled SR-IOV. These labels specify which nodes the SR-IOV config daemonset will run on.

    ```
    oc label nodes <node-ip> feature.node.kubernetes.io/network-sriov.capable=true
    ```

7. Now that the bare metal servers are configured for SR-IOV, install the [OpenShift SR-IOV operator](https://docs.openshift.com/container-platform/4.6/networking/hardware_networks/installing-sriov-operator.html).

    The operator allows you to set up the SR-IOV network on your cluster.

8. Disable webhooks for the SR-IOV operator.

    ```
    oc patch sriovoperatorconfig default --type=merge \
      -n openshift-sriov-network-operator \
      --patch '{ "spec": { "enableOperatorWebhook": false} }'
    ```

The SR-IOV OpenShift operator is now installed in your cluster. Continue on to the next topic to deploy sample SR-IOV networks and applications.

## Deploy an SR-IOV network to your OpenShift cluster

To test out SR-IOV functions, deploy the following resources.

1. Create node policy.
    The node policy selects which nodes are part of the SR-IOV network.

    `kubectl apply -f  https://raw.githubusercontent.com/IBM-Cloud/kube-samples/master/satellite-sr-iov/sriov-node-policy.yaml`

2. Apply the SR-IOV network
    
    `kubectl apply -f https://raw.githubusercontent.com/IBM-Cloud/kube-samples/master/satellite-sr-iov/sriov-network.yaml`

3. Create two pods that use the SR-IOV network.
    
    `kubectl apply -f https://raw.githubusercontent.com/IBM-Cloud/kube-samples/master/satellite-sr-iov/sriov-pods.yaml`

4. Run tests to confirm pods can communicate.

    1. Attach to pod `test-sriov-1` to ping `test-sriov-2`. 

        `oc exec -it test-sriov-1 sh`

    2. Use ping to confirm connectivity over the SR-IOV network. 
        
        `ping -I net1 192.168.99.12`

        ```
        PING 192.168.99.12 (192.168.99.12) from 192.168.99.11 net1: 56(84) bytes of data.
        64 bytes from 192.168.99.12: icmp_seq=2 ttl=64 time=0.095 ms
        ```

You now have set up an SR-IOV network on your OpenShift cluster.

For more reading on setting up an SR-IOV network:

* [Enhanced Platform Awareness (EPA) in OpenShift](https://medium.com/swlh/enhanced-platform-awareness-epa-in-openshift-part-iv-sr-iov-dpdk-and-rdma-1cc894c4b7d0) 
    