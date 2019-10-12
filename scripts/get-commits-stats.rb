#!/usr/bin/env ruby

# Copyright (C) 2019 Fondazione Istituto Italiano di Tecnologia (IIT)
# Authors: Ugo Pattacini <ugo.pattacini@iit.it>
# CopyPolicy: Released under the terms of the GNU GPL v3.0.
#
# Dependencies (through gem):
# - octokit
#

require 'octokit'

Signal.trap("INT") {
  exit 2
}

Signal.trap("TERM") {
  exit 2
}

# global variables
$client = Octokit::Client.new
$ranks = Hash.new(0)
$contrib_repos = Hash.new("")

def help_n_exit()
  puts "Usage: $0 --input-file=<repositories> [--output-file=<details>] [--token=<github-token>]"
  puts "       $0 --org=<organization> [--output-file=<file-name>] [--token=<github-token>]"
  exit 1
end

def get_repositories(org)
  repos = ""
  loop do
    $client.org_repos(org, {:type => 'all'})
    rate_limit = $client.rate_limit
    if rate_limit.remaining > 0 then
      break
    end
    sleep(60)
  end
  last_response = $client.last_response
  data = last_response.data
  data.each { |x| repos = repos + "#{x.full_name}\n" }
  until last_response.rels[:next].nil?
    last_response = last_response.rels[:next].get
    data = last_response.data
    data.each { |x| repos = repos + "#{x.full_name}\n" }
  end
  return repos
end

def fill(item,repo)
  login = item.author.login
  commits = item.total
  $ranks[login] = $ranks[login] + commits
  $contrib_repos[login] = $contrib_repos[login] + repo + "(" + commits.to_s + "); "
end

# process command line options
args = Hash[ ARGV.join(' ').scan(/--?([^=\s]+)(?:=(\S+))?/) ]
if ARGV.length < 1 then
  help_n_exit()
end
if !args["input-file"].nil?
  repos = File.open(args["input-file"]).read
  repos.gsub!(/\r\n?/, "\n")
elsif !args["org"].nil?
  repos = get_repositories(args["org"])
else
  puts "invalid syntax!"
  help_n_exit()
end
if !args["token"].nil?
  $client.access_token = args["token"]
end

# get users' commits for each repo
repos.each_line do |line|
  repo = line.strip.sub("\n","")
  if !repo.nil?

    loop do
      $client.contributors_stats(repo)
      rate_limit = $client.rate_limit
      if rate_limit.remaining > 0 then
        break
      end
      sleep(60)
    end

    last_response = $client.last_response
    data = last_response.data
    data.each { |x| fill(x,repo) }

    until last_response.rels[:next].nil?
      last_response = last_response.rels[:next].get
      data = last_response.data
      data.each { |x| fill(x,repo) }
    end

  end
end
$ranks = $ranks.sort_by { |user, commits| commits }.to_h

# produce output
if !args["output-file"].nil?
  output_file=File.open(args["output-file"], 'w')
end
$ranks.each { |user, commits|
  name = $client.user(user).name
  repos_list = $contrib_repos[user]
  puts "#{user} (#{name}): #{commits}"
  if !args["output-file"].nil?
    output_file.write("#{user} (#{name}): #{commits} - #{repos_list}\n")
  end
}
if !args["output-file"].nil?
  output_file.close
end  