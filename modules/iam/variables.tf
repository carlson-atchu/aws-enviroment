variable "revoke_sessions_before" {
  description = "Deny sessions issued before this ISO 8601 timestamp (AWSRevokeOlderSessions). Update when rotating credentials."
  type        = string
  default     = "2026-02-09T15:51:57.022Z"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
