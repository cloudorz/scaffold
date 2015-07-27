#!/usr/bin/env ruby 

require 'fileutils' 


EXEC_FILE_NAME = File.basename $0
EXEC_EXT_NAME = File.extname $0
EXEC_NAME = File.basename($0, EXEC_EXT_NAME)
COMMAND_NAME_SUFFIX = "_trunk"
VERSION = "0.3"

def install
    puts "Install ......"
    puts "Input the private cocoaPods repo name: "
    repo_name = gets.chomp
    if repo_name.empty?
        puts "ERR:: The private cocoaPods repo name cant be empty."
    else
        exec_script_name = repo_name + COMMAND_NAME_SUFFIX
        FileUtils.install $0, "/usr/local/bin/#{exec_script_name}", :mode => 0755, :verbose => false
        puts "Done!"
    end
end

def repo_name_from_exec_name 
    pieces = EXEC_NAME.split('_')
    pieces.pop
    pieces.join '_'
end

def update_repo repo_name
    update_result = `pod repo update #{repo_name}`
    puts update_result
    if update_result.start_with? "[!] Unable to find the"
        puts "ERR:: The '#{repo_name}' is not existed. Use 'pod repo add <name> <repo url>' to add it."
    else
        if block_given?
            yield repo_name
        end
    end
end

def parse_spec_name_and_version_from_podspec file_path
    podspec_json_string = `pod ipc spec #{file_path}`

    require 'json'
    podspec_json = JSON.parse podspec_json_string
    if podspec_json and podspec_json["name"] and podspec_json["version"]
        if block_given?
            yield podspec_json["name"], podspec_json["version"]
        else
            [podspec_json["name"], podspec_json["version"]]
        end
    else
        puts "ERR:: Parse podspec json string fail."
    end
end

def get_podspec_file_path
    file_path = Dir.glob("./*.podspec").first
    if file_path.nil? or file_path.empty?
        puts "ERR:: podspec file does not exist."
    else
        if block_given?
            yield file_path
        else
            file_path
        end
    end
end

def commit_and_push(file_path, repo_spec_path, message)
    puts "Start push the new version podspec ......"
    FileUtils.mkdir_p repo_spec_path
    FileUtils.cp file_path, repo_spec_path
    FileUtils.cd(repo_spec_path) do
        system "git add . && git commit -m'#{message}' && git push"
    end
    puts "Done!"
end

def version
    VERSION
end

def tag_exist_on_remote? spec_version
    result = `git ls-remote --tags origin refs/tags/#{spec_version}`
    not (result.nil? or result.empty?)
end

def tag_exist_in_local? spec_version
    result = `git tag -l #{spec_version}`
    not (result.nil? or result.empty?)
end

def push_spec_version_tag spec_version
    if tag_exist_on_remote? spec_version
        if block_given?
            yield
        end
    else
        if tag_exist_in_local? spec_version
            `git push --tags`
            if block_given?
                yield
            end
        else
            `git tag #{spec_version} && git push --tags`
            if block_given?
                yield
            end
        end
    end
end

def local_has_uncommits?
    result = `git status`
    not result.end_with? "nothing to commit, working directory clean\n"
end

def repo_not_sync?
    result = `git status | grep -E 'ahead|behind'`
    (result and not result.empty?)
end

def check_local_remote_repo_sync
    if local_has_uncommits? or repo_not_sync?
        puts "ERR:: The loal repo is not sync with remote repo."
    else
        if block_given?
            yield
        end
    end
end

unless EXEC_FILE_NAME == "install.rb"
    if ['-v', '--version'].include? ARGV.first
        puts "latest version: #{version}" 
    else
        get_podspec_file_path do |file_path|
            check_local_remote_repo_sync do
                parse_spec_name_and_version_from_podspec file_path do |spec_name, spec_version|
                    push_spec_version_tag spec_version do
                        update_repo repo_name_from_exec_name do |repo_name|
                            repo_all_path = File.join(Dir.home, ".cocoaPods", "repos", repo_name, "Specs", spec_name, spec_version)
                            unless Dir.exist? repo_all_path 
                                git_user_name = `git config user.name`
                                message = "- [Add] #{spec_name} #{spec_version} by #{git_user_name}"
                                commit_and_push file_path, repo_all_path, message
                            else
                                puts "ERR:: The version #{spec_version} of #{spec_name} is existed."
                            end
                        end
                    end
                end
            end
        end
    end
else
    install
end

