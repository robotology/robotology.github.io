#!/usr/bin/env python

import sys
from github import Github

g = None

def get_repo_commits(repo):
    total = 0
    cas = repo.get_stats_commit_activity()
    if cas is not None:
        total = 0
        for ca in cas:
            total = total + ca.total
#    print repo.name, ":", total
    return total

def get_organization_commits(organization):
    total = 0
    print "=====", organization.name
    for repo in organization.get_repos():
        total = total + get_repo_commits(repo)
    print "=====", organization.name, "total :", total
    return total

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print "Usage:", sys.argv[0], "<token>"
        sys.exit(1)

    token = sys.argv[1]
    print "Using token", token
    g = Github(token)
    total = 0

    for org_name in [ "robotology", "robotology-playground", "robotology-legacy" ]:
        org = g.get_organization(org_name)
        total = total + get_organization_commits(org)

    print "==========================="
    print "Total :", total
