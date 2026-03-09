output "control_plane_ip" {
  description = "SSH to control plane"
  value       = aws_instance.control_plane.public_ip
}

output "worker_ip" {
  description = "SSH to worker node"
  value       = aws_instance.worker.public_ip
}

output "ssh_control_plane" {
  description = "Ready-to-use SSH command"
  value       = "ssh -i ~/.ssh/id_rsa rocky@${aws_instance.control_plane.public_ip}"
}

output "ssh_worker" {
  description = "Ready-to-use SSH command"
  value       = "ssh -i ~/.ssh/id_rsa rocky@${aws_instance.worker.public_ip}"
}