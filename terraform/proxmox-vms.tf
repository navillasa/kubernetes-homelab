# NOTE: k8s-node1 was created manually via Proxmox UI
# This resource definition serves as a template for creating future VMs with Terraform

# resource "proxmox_vm_qemu" "k8s_node1" {
#   name        = "k8s-node1"
#   target_node = var.proxmox_node
#   desc        = "Main Kubernetes cluster running MicroK8s"
#
#   vmid     = 100
#   os_type  = "l26"
#   cores    = 3
#   sockets  = 1
#   cpu      = "x86-64-v2-AES"
#   memory   = 12288
#
#   boot     = "order=scsi0"
#   agent    = 1
#
#   disk {
#     slot    = 0
#     size    = "200G"
#     type    = "scsi"
#     storage = "local-lvm"
#   }
#
#   network {
#     model  = "virtio"
#     bridge = "vmbr0"
#   }
#
#   lifecycle {
#     ignore_changes = [
#       network,
#       disk,
#     ]
#   }
# }
