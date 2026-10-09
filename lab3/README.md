# Lab 3

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 3 in this folder.
A real AWS account should use OpenID Connect (OIDC) to let GitHub Actions assume an IAM role and obtain temporary AWS credentials, rather than storing long-lived access keys as GitHub secrets, because OIDC reduces the risk of credential theft and exposure.

This course uses session-scoped secrets to provide temporary credentials for a limited lab session, and the damage from a leak is limited by their expiration, the IAM permissions granted to the session, and any applicable resource or account restrictions.

