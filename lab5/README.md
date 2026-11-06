# Lab 5

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 5 in this folder.
## Why for_each here and count there

### Why subnets use for_each

Subnets are distinct resources with stable names, so `for_each` is the better choice. Each subnet is identified by its map key.

- Adding key `c` creates only one new subnet: 1 to add, 0 to change, 0 to destroy.
- Removing key `a` destroys only that subnet. Subnet `b` remains untouched.

### Why count would be a trap for subnets

Using `count` would assign numeric addresses such as `[0]`, `[1]`, and `[2]`. If the middle entry were removed, the remaining entries would shift down. Terraform could compare the old resource at `[1]` with a different subnet in the configuration and plan to destroy and recreate two subnets just to remove one.

### Why the bucket uses count

The artifact bucket is optional: the input is a yes/no decision about one resource. `count` is appropriate because there is no collection of distinct named buckets to track.

There are two possible plans:
- `create_artifact_bucket = false`: 0 buckets added.
- `create_artifact_bucket = true`: 1 bucket added.

In short: **use count when the question is how many, and for_each when the question is which ones.**
