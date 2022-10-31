# Copyright 2022 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
---
- name: Avi Controller Configuration
  hosts: localhost
  connection: local
  gather_facts: no
  roles:
    - role: avinetworks.avisdk
  vars:
    avi_credentials:
        controller: "{{ controller_ip[0] }}"
        username: "{{ username }}"
        password: "{{ password }}"
        api_version: "{{ api_version }}"
    username: "admin"
    password: "{{ password }}"
    api_version: ${avi_version}
    cloud_name: "Default-Cloud"
    controller_ip:
      ${ indent(6, yamlencode(controller_ip))}
    controller_names:
      ${ indent(6, yamlencode(controller_names))}
    dns_search_domain: ${dns_search_domain}
    ansible_become: yes
    ansible_become_password: "{{ password }}"
    vpc_network_name: ${se_vpc_network_name}
    vpc_subnet_name: ${se_mgmt_subnet_name}
    vpc_project_id: ${vpc_project_id}
    region: ${region}
    se_project_id: ${se_project_id}
    gcs_project_id: ${gcs_project_id}
    name_prefix: ${name_prefix}
    se_size:
      cpu: ${se_size[0]}
      memory: ${se_size[1]}
      disk: ${se_size[2]}
    se_ha_mode: ${se_ha_mode}
    vip_allocation_strategy: ${vip_allocation_strategy}
    controller_ha: ${controller_ha}
%{ if se_service_account != null ~}
    gcp_service_account_email: ${se_service_account}
%{ endif ~}
%{ if dns_servers != null ~}
    dns_servers:
%{ for item in dns_servers ~}
      - addr: "${item}"
        type: "V4"
%{ endfor ~}
%{ endif ~}
    ntp_servers:
%{ for item in ntp_servers ~}
      - server:
          addr: "${item.addr}"
          type: "${item.type}"
%{ endfor ~}
    configure_ipam_profile: ${configure_ipam_profile}
    ipam_networks:
%{ if configure_ipam_profile ~}
      ${ indent(6, yamlencode(ipam_networks))}
%{ else ~}
      - "network": "{{ ipam_network_1 | default('192.168.251.0/24') }}"
        "static_pool":
        - "{{ ipam_network_1_start | default('192.168.251.10') }}"
        - "{{ ipam_network_1_end | default('192.168.251.254') }}"
%{ endif ~}
    configure_dns_profile:
      ${ indent(6, yamlencode(configure_dns_profile))}
    configure_dns_vs:
      ${ indent(6, yamlencode(configure_dns_vs))}
    configure_gslb:
      ${ indent(6, yamlencode(configure_gslb))}
    gslb_user: "gslb-admin"
%{ if vip_allocation_strategy == "ILB" ~}
    cloud_router: ${cloud_router}
%{ endif ~}
%{ if avi_upgrade.enabled || register_controller.enabled  ~}
    avi_upgrade:
      enabled: ${avi_upgrade.enabled}
    register_controller:
      enabled: ${register_controller.enabled}
%{ endif ~}
  tasks:
    - name: Wait for Controller to become ready
      wait_for:
        port: 443
        timeout: 600
        sleep: 5

    - name: Configure System Configurations
      avi_systemconfiguration:
        avi_credentials: "{{ avi_credentials }}"
        state: present
        email_configuration:
          smtp_type: "SMTP_LOCAL_HOST"
          from_email: admin@avicontroller.net
        global_tenant_config:
          se_in_provider_context: true
          tenant_access_to_provider_se: true
          tenant_vrf: false
%{ if dns_servers != null ~}
        dns_configuration:
          server_list: "{{ dns_servers }}"
          search_domain: "{{ dns_search_domain }}"
%{ endif ~}
        ntp_configuration:
          ntp_servers: "{{ ntp_servers }}"
        portal_configuration:
          allow_basic_authentication: false
          disable_remote_cli_shell: false
          enable_clickjacking_protection: true
          enable_http: true
          enable_https: true
          password_strength_check: true
          redirect_to_https: true
          use_uuid_from_input: false
        welcome_workflow_complete: true
        
    - name: Configure Cloud
      avi_cloud:
        avi_credentials: "{{ avi_credentials }}"
        state: present
        avi_api_update_method: patch
        avi_api_patch_op: replace
        name: "{{ cloud_name }}"
        vtype: CLOUD_GCP
        dhcp_enabled: true
        license_type: "LIC_CORES" 
        gcp_configuration:
          region_name: "{{ region }}"
          se_project_id: "{{ se_project_id }}"
          gcs_project_id: "{{ gcs_project_id }}"
          zones: %{ for zone in zones }
            - "${zone}"
            %{ endfor }
          network_config:
            config:  "INBAND_MANAGEMENT"
            inband:
              vpc_subnet_name: "{{ vpc_subnet_name }}"
              vpc_project_id: "{{ vpc_project_id }}"
              vpc_network_name: "{{ vpc_network_name }}"
          firewall_target_tags:
            - "avi-se"
          dhcp_enabled: false
          vip_allocation_strategy:
            mode: "{{ vip_allocation_strategy }}" %{ if vip_allocation_strategy == "ILB" }
            ilb:
              cloud_router_names:
                - "{{ cloud_router }}"
            %{ endif }
%{ if se_service_account != null ~}
          gcp_service_account_email: "{{ gcp_service_account_email }}"
%{ endif ~}
      register: avi_cloud

    - name: Set Backup Passphrase
      avi_backupconfiguration:
        avi_credentials: "{{ avi_credentials }}"
        state: present
        name: Backup-Configuration
        backup_passphrase: "{{ password }}"
        upload_to_remote_host: false

%{ if se_ha_mode == "active/active" ~}
    - name: Configure SE-Group
      avi_serviceenginegroup:
        avi_credentials: "{{ avi_credentials }}"
        tenant: "admin"
        name: "Default-Group" 
        avi_credentials: "{{ avi_credentials }}"
        state: present
        cloud_ref: "/api/cloud?name={{ cloud_name }}"
        ha_mode: HA_MODE_SHARED_PAIR
        min_scaleout_per_vs: 2
        algo: PLACEMENT_ALGO_PACKED
        buffer_se: "0"
        max_se: "10"
        se_name_prefix: "{{ name_prefix }}"
        vcpus_per_se: "{{ se_size.cpu }}"
        memory_per_se: "{{ se_size.memory * 1024 }}"
        disk_per_se: "{{ se_size.disk }}"
        realtime_se_metrics:
          duration: "60"
          enabled: true
%{ endif ~}
%{ if se_ha_mode == "n+m" ~}
    - name: Configure SE-Group
      avi_serviceenginegroup:
        avi_credentials: "{{ avi_credentials }}"
        tenant: "admin"
        name: "Default-Group" 
        avi_credentials: "{{ avi_credentials }}"
        state: present
        cloud_ref: "/api/cloud?name={{ cloud_name }}"
        ha_mode: HA_MODE_SHARED
        min_scaleout_per_vs: 1
        algo: PLACEMENT_ALGO_PACKED
        buffer_se: "1"
        max_se: "10"
        se_name_prefix: "{{ name_prefix }}"
        vcpus_per_se: "{{ se_size.cpu }}"
        memory_per_se: "{{ se_size.memory * 1024 }}"
        disk_per_se: "{{ se_size.disk }}"
        realtime_se_metrics:
          duration: "60"
          enabled: true
%{ endif ~}
%{ if se_ha_mode == "active/standby" ~}
    - name: Configure SE-Group
      avi_serviceenginegroup:
        avi_credentials: "{{ avi_credentials }}"
        tenant: "admin"
        name: "Default-Group" 
        avi_credentials: "{{ avi_credentials }}"
        state: present
        cloud_ref: "/api/cloud?name={{ cloud_name }}"
        ha_mode: HA_MODE_LEGACY_ACTIVE_STANDBY
        min_scaleout_per_vs: 1
        buffer_se: "0"
        max_se: "2"
        se_name_prefix: "{{ name_prefix }}"
        vcpus_per_se: "{{ se_size.cpu }}"
        memory_per_se: "{{ se_size.memory * 1024 }}"
        disk_per_se: "{{ se_size.disk }}"
        realtime_se_metrics:
          duration: "60"
          enabled: true
%{ endif ~}
    - name: Configure IPAM Profile
      block:
        - name: Update IPAM Network Objects with Static Pool
          avi_network:
            avi_credentials: "{{ avi_credentials }}"
            state: present
            avi_api_update_method: patch
            avi_api_patch_op: add
            name: "network-{{ item.network }}"
            dhcp_enabled: false
            configured_subnets:
              - prefix:
                  ip_addr:
                    addr: "{{ item.network | ipaddr('network') }}"
                    type: "V4"
                  mask: "{{ item.network | ipaddr('prefix') }}"
                static_ip_ranges:
                - range:
                    begin:
                      addr: "{{ item.static_pool.0 }}"
                      type: "V4"
                    end:
                      addr: "{{ item.static_pool.1 }}"
                      type: "V4"
                  type: STATIC_IPS_FOR_VIP_AND_SE
            ip6_autocfg_enabled: false
          loop: "{{ ipam_networks }}"
          register: ipam_net
        - name: Create list with IPAM Network URLs
          set_fact: ipam_net_urls="{{ ipam_net.results | map(attribute='obj.url') | list }}"
        - name: Create list formated for Avi IPAM profile API
          set_fact:
            ipam_list: "{{ ipam_list | default([]) + [{ 'nw_ref': item  }] }}"
          loop: "{{ ipam_net_urls }}"
        - name: Create Avi IPAM Profile
          avi_ipamdnsproviderprofile:
            avi_credentials: "{{ avi_credentials }}"
            state: present
            name: Avi_IPAM
            type: IPAMDNS_TYPE_INTERNAL
            internal_profile:
              ttl: 30
              usable_networks: "{{ ipam_list }}"
            allocate_ip_in_vrf: false
          register: create_ipam

        - name: Update Cloud Configuration with IPAM profile 
          avi_cloud:
            avi_credentials: "{{ avi_credentials }}"
            avi_api_update_method: patch
            avi_api_patch_op: add
            name: "{{ cloud_name }}"
            ipam_provider_ref: "{{ create_ipam.obj.url }}"
            vtype: CLOUD_GCP
      when: configure_ipam_profile == true
      tags: ipam_profile

    - name: Configure DNS Profile
      block:
        - name: Create Empty List for dns_service_domain API field
          set_fact:
            dns_service_domain: []
          when: configure_dns_profile.type == "AVI"

        - name: Build list for dns_service_domain API field
          set_fact:
            dns_service_domain: "{{ dns_service_domain | default([]) + [{'domain_name': domain, 'pass_through': 'true' }] }}"
          loop: "{{ configure_dns_profile.usable_domains }}"
          loop_control:
            loop_var: domain
          when: configure_dns_profile.type == "AVI"

        - name: Create Avi DNS Profile
          avi_ipamdnsproviderprofile:
            avi_credentials: "{{ avi_credentials }}"
            state: present
            name: "Avi_DNS"
            type: "IPAMDNS_TYPE_INTERNAL_DNS"          
            internal_profile:
              dns_service_domain: "{{ dns_service_domain }}"
              ttl: "{{ configure_dns_profile.ttl | default('30') }}"
          register: create_dns_avi
          when: configure_dns_profile.type == "AVI"

        - name: Update Cloud Configuration with DNS profile 
          avi_cloud:
            avi_credentials: "{{ avi_credentials }}"
            avi_api_update_method: patch
            avi_api_patch_op: add
            name: "{{ cloud_name }}"
            dns_provider_ref: "{{ create_dns_avi.obj.url }}"
            vtype: CLOUD_GCP
          when: configure_dns_profile.type == "AVI"

        - name: Create AWS Route53 DNS Profile
          avi_ipamdnsproviderprofile:
            avi_credentials: "{{ avi_credentials }}"
            state: present
            name: "AWS_R53_DNS"
            type: "IPAMDNS_TYPE_AWS_DNS"
            aws_profile:
              iam_assume_role: "{{ configure_dns_profile.aws_profile.iam_assume_role }}"
              access_key_id: "{{ configure_dns_profile.aws_profile.access_key_id }}"
              secret_access_key: "{{ configure_dns_profile.aws_profile.secret_access_key }}"
              region: "{{ configure_dns_profile.aws_profile.region }}"
              vpc_id: "{{ configure_dns_profile.aws_profile.vpc_id }}"
              usable_domains: "{{ configure_dns_profile.usable_domains }}"
              ttl: "{{ configure_dns_profile.ttl | default('30') }}"
          register: create_dns_aws
          when: configure_dns_profile.type == "AWS"
        
        - name: Update Cloud Configuration with DNS profile
          avi_cloud:
            avi_credentials: "{{ avi_credentials }}"
            avi_api_update_method: patch
            avi_api_patch_op: add
            name: "{{ cloud_name }}"
            dns_provider_ref: "{{ create_dns_aws.obj.url }}"
            vtype: CLOUD_AZURE
          when: configure_dns_profile.type == "AWS"
      when: configure_dns_profile.enabled == true
      tags: dns_profile
      ignore_errors: yes

    - name: Configure GSLB SE Group and Account
      block:
        - name: Configure GSLB SE-Group
          avi_serviceenginegroup:
            avi_credentials: "{{ avi_credentials }}"
            tenant: "admin"
            name: "g-dns" 
            cloud_ref: "/api/cloud?name={{ cloud_name }}"
            ha_mode: HA_MODE_SHARED_PAIR
            min_scaleout_per_vs: 2
            algo: PLACEMENT_ALGO_PACKED
            buffer_se: "0"
            max_se: "4"
            max_vs_per_se: "1"
            extra_shared_config_memory: 2000
            se_name_prefix: "{{ name_prefix }}{{ configure_gslb.site_name }}"
            vcpus_per_se: "{{ configure_gslb.se_size.0 }}"
            memory_per_se: "{{ configure_gslb.se_size.1 }}"
            disk_per_se: "{{ configure_gslb.se_size.2 }}"
            realtime_se_metrics:
              duration: "60"
              enabled: true
          register: gslb_se_group
          when: configure_gslb.create_se_group == true or configure_gslb.create_se_group == "null"


        - name: Create User for GSLB
          avi_user:
            avi_credentials: "{{ avi_credentials }}"
            default_tenant_ref: "/api/tenant?name=admin"
            state: present
            name: "{{ gslb_user }}"
            access:
              - all_tenants: true
                role_ref: "/api/role?name=System-Admin"
            email: "{{ user_email | default(omit) }}"
            user_profile_ref: "/api/useraccountprofile?name=No-Lockout-User-Account-Profile"
            is_superuser: false
            obj_password: "{{ password }}"
            obj_username: "{{ gslb_user }}"
      when: configure_gslb.enabled == true
      tags: gslb

    - name: Configure DNS Virtual Service
      block:
        - name: Create DNS VSVIP
          avi_vsvip:
            avi_credentials: "{{ avi_credentials }}"
            tenant: "admin"
            cloud_ref: "/api/cloud?name={{ cloud_name }}"
            vip:
            - enabled: true
              vip_id: 0
%{ if configure_dns_vs.auto_allocate_ip == "false" ~}
              ip_address:
                addr: "{{ configure_dns_vs.vs_ip }}"
                type: "V4"
%{ endif ~}            
              auto_allocate_ip: "{{ configure_dns_vs.auto_allocate_ip }}"
%{ if configure_dns_vs.auto_allocate_ip ~}
              auto_allocate_floating_ip: "{{ configure_dns_vs.allocate_public_ip }}"
%{ endif ~}
              avi_allocated_vip: false
              avi_allocated_fip: false
              auto_allocate_ip_type: V4_ONLY
              prefix_length: 32
              placement_networks: []
              ipam_network_subnet:
                network_ref: "/api/network/?name=network-{{ configure_dns_vs.network }}"
                subnet:
                  ip_addr:
                    addr: "{{ configure_dns_vs.network | ipaddr('network') }}"
                    type: V4
                  mask: "{{ configure_dns_vs.network | ipaddr('prefix') }}"
            dns_info:
            - type: DNS_RECORD_A
              algorithm: DNS_RECORD_RESPONSE_CONSISTENT_HASH
              fqdn: "dns.{{ configure_dns_profile.usable_domains.0 }}"
            name: vsvip-DNS-VS-Default-Cloud
          register: vsvip_results

        - name: Display DNS VS VIP
          ansible.builtin.debug:
            var: vsvip_results

        - name: Create DNS Virtual Service
          avi_api_session:
            avi_credentials: "{{ avi_credentials }}"
            http_method: post
            path: "virtualservice"
            tenant: "admin"
            data:
              name: DNS-VS
              enabled: true
              analytics_policy:
                full_client_logs:
                  enabled: true
                  duration: 30
                metrics_realtime_update:
                  enabled: true
                  duration: 30
              traffic_enabled: true
              application_profile_ref: /api/applicationprofile?name=System-DNS
              network_profile_ref: /api/networkprofile?name=System-UDP-Per-Pkt
              analytics_profile_ref: /api/analyticsprofile?name=System-Analytics-Profile
%{ if configure_gslb.enabled ~}
              se_group_ref: "{{ gslb_se_group.obj.url }}"
%{ endif ~}
              cloud_ref: "/api/cloud?name={{ cloud_name }}"
              services:
              - port: 53
                port_range_end: 53
              - port: 53
                port_range_end: 53
                override_network_profile_ref: /api/networkprofile/?name=System-TCP-Proxy
              vsvip_ref: "{{ vsvip_results.obj.url }}"
          register: dns_vs

        - name: Add DNS-VS to System Configuration
          avi_systemconfiguration:
            avi_credentials: "{{ avi_credentials }}"
            avi_api_update_method: patch
            avi_api_patch_op: add
            tenant: admin
            dns_virtualservice_refs: "{{ dns_vs.obj.url }}"
      when: configure_dns_vs.enabled == true
      tags: configure_dns_vs

    - name: Configure GSLB
      block:
        - name: GSLB Config | Verify Cluster UUID
          avi_api_session:
            avi_credentials: "{{ avi_credentials }}"
            http_method: get
            path: cluster
          register: cluster

        - name: Create Empty List for controller ip_addresses API field
          set_fact:
            controller_ip_addresses: []
          
        - name: Build list for gslb ip_addresses API field
          set_fact:
            controller_ip_addresses: "{{ controller_ip_addresses | default([]) + [{ 'type': 'V4','addr': ip }] }}"
          loop: "{{ controller_ip }}"
          loop_control:
            loop_var: ip

        - name: Create Empty List for dns_configs API field
          set_fact:
            gslb_domains: []
          
        - name: Build list for dns_configs API field
          set_fact:
            gslb_domains: "{{ gslb_domains | default([]) + [{ 'domain_name': domain }] }}"
          loop: "{{ configure_gslb.domains }}"
          loop_control:
            loop_var: domain
          ignore_errors: yes

        - name: Create GSLB Config
          avi_gslb:
            avi_credentials: "{{ avi_credentials }}"
            name: "GSLB"
            sites:
              - name: "{{ configure_gslb.site_name }}"
                username: "{{ gslb_user }}"
                password: "{{ password }}"
                ip_addresses: "{{ controller_ip_addresses }}"
                enabled: True
                member_type: "GSLB_ACTIVE_MEMBER"
                port: 443
                dns_vses:
                  - dns_vs_uuid: "{{ dns_vs.obj.uuid }}"
                cluster_uuid: "{{ cluster.obj.uuid }}"
            dns_configs: "{{ gslb_domains }}"
            leader_cluster_uuid: "{{ cluster.obj.uuid }}"
          register: gslb_results
      when: configure_gslb.enabled == true and configure_gslb.leader == true
      tags: gslb

    - name: Configure Additional GSLB Sites
      block:
      - name: Include gslb-add-site-tasks.yml in play
        include_tasks: gslb-add-site-tasks.yml
        loop: "{{ configure_gslb.additional_sites }}"
        loop_control:
          loop_var: site
      when: configure_gslb.additional_sites != "null"
      tags:
        - configure_gslb_additional_sites
        - gslb
      ignore_errors: yes

    - name: Controller Cluster Configuration
      avi_cluster:
        avi_credentials: "{{ avi_credentials }}"
        state: present
        #virtual_ip:
        #  type: V4
        #  addr: "{{ controller_cluster_vip }}"
        nodes:
            - name:  "{{ controller_names[0] }}" 
              password: "{{ password }}"
              ip:
                type: V4
                addr: "{{ controller_ip[0] }}"
            - name:  "{{ controller_names[1] }}" 
              password: "{{ password }}"
              ip:
                type: V4
                addr: "{{ controller_ip[1] }}"
            - name:  "{{ controller_names[2] }}" 
              password: "{{ password }}"
              ip:
                type: V4
                addr: "{{ controller_ip[2] }}"
%{ if configure_gslb.enabled ~}
        name: "{{ name_prefix }}-{{ configure_gslb.site_name }}-cluster"
%{ else ~}
        name: "{{ name_prefix }}-cluster"
%{ endif ~}
        tenant_uuid: "admin"
      until: cluster_config is not failed
      retries: 10
      delay: 5
      register: cluster_config
      when: controller_ha == true
      tags: controller_ha

    - name: Add Prerequisites for avi-cloud-services-registration.yml Play
      block:
        - name: Install Avi Collection
          shell: ansible-galaxy collection install vmware.alb -p /home/admin/.ansible/collections

        - name: Copy Ansible module file
          ansible.builtin.copy:
            src: /home/admin/ansible/avi_pulse_registration.py
            dest: /home/admin/.ansible/collections/ansible_collections/vmware/alb/plugins/modules/avi_pulse_registration.py
        
        - name: Remove unused module file
          ansible.builtin.file:
            path: /home/admin/avi_pulse_registration.py
            state: absent
%{ if split(".", avi_version)[0] == "21" && split(".", avi_version)[2] == "4"  ~}

        - name: Patch file
          shell: patch --directory /opt/avi/python/bin/portal/api/ < /home/admin/ansible/views_albservices.patch

        - name: Restart Avi Portal
          ansible.builtin.systemd:
            state: restarted
            name: aviportal
%{ endif ~}
      tags: register_controller

    - name: Remove patch file
      ansible.builtin.file:
        path: /home/admin/ansible/views_albservices.patch
        state: absent

%{ if avi_upgrade.enabled || register_controller.enabled  ~}
    - name: Verify Cluster State if avi_upgrade or register_controller plays will be ran
      block:
        - name: Pause for 8 minutes for Cluster to form
          ansible.builtin.pause:
            minutes: 8
    
        - name: Wait for Avi Cluster to be ready
          avi_api_session:
            avi_credentials: "{{ avi_credentials }}"
            http_method: get
            path: "cluster/runtime"
          until: cluster_check is not failed
          retries: 60
          delay: 10
          register: cluster_check

        - name: Wait for Avi Cluster to be ready
          avi_api_session:
            avi_credentials: "{{ avi_credentials }}"
            http_method: get
            path: "cluster/runtime"
          until: cluster_runtime.obj.cluster_state.state == "CLUSTER_UP_HA_ACTIVE"
          retries: 60
          delay: 10
          register: cluster_runtime
      when: (controller_ha == true and avi_upgrade.enabled == true) or
            (controller_ha == true and register_controller.enabled == true)
      tags: verify_cluster
%{ endif ~}