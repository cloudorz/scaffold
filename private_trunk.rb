#!/usr/bin/env ruby 

require 'fileutils' 


EXEC_FILE_NAME = File.basename $0
EXEC_EXT_NAME = File.extname $0
EXEC_NAME = File.basename($0, EXEC_EXT_NAME)
COMMAND_NAME_SUFFIX = "_trunk"
VERSION = "0.1"

def install
    puts "Input the private cocoaPods repo name: "
    repo_name = gets.chomp
    if repo_name.empty?
        puts "The private cocoaPods repo name cant be empty."
    else
        exec_script_name = repo_name + COMMAND_NAME_SUFFIX
        FileUtils.install $0, "/usr/local/bin/#{exec_script_name}", :mode => 0755, :verbose => true
    end
end

def repo_name_from_exec_name 
    pieces = EXEC_NAME.split('_')
    pieces.pop
    pieces.join '_'
end

def update_repo_ok? repo_name
    update_result = `pod repo update #{repo_name}`
    puts update_result
    if update_result.start_with? "[!] Unable to find the"
        puts "ERR:: The '#{repo_name}' is not existed. Use 'pod repo add <name> <repo url>' to add it."
        false
    else
        true
    end
end

def parse_spec_name_and_version_from_podspec file_path
    podspec_json_string = `pod ipc spec #{file_path}`

    require 'json'
    podspec_json = JSON.parse podspec_json_string
    if podspec_json and podspec_json["name"] and podspec_json["version"]
        [podspec_json["name"], podspec_json["version"]]
    else
        puts "ERR:: Parse podspec json string fail."
        [nil, nil]
    end
end

def podspec_file_path
    file_path = Dir.glob("./*.podspec").first
    if file_path.nil? or file_path.empty?
        puts "ERR:: podspec file does not exist."
        nil
    else
        file_path
    end
end

def commit_and_push(file_path, repo_spec_path, message)
    require 'fileutils'
    FileUtils.mkdir_p repo_spec_path
    FileUtils.cp file_path, repo_spec_path
    FileUtils.cd(repo_spec_path) do
        system "git add . && git commit -m'#{message}' && git push"
    end
end

def version
    VERSION
end

unless EXEC_FILE_NAME == "install.rb"
    if ['-v', '--version'].include? ARGV.first
        puts "latest version: #{version}" 
    else
        file_path = podspec_file_path
        if file_path
            spec_name, spec_version = parse_spec_name_and_version_from_podspec file_path
            if spec_name and spec_version
                private_repo_name = repo_name_from_exec_name
                if update_repo_ok? private_repo_name
                    repo_all_path = File.join(Dir.home, ".cocoapods", "repos", private_repo_name, "Specs", spec_name, spec_version)
                    unless Dir.exist? repo_all_path 
                        git_user_name = `git config user.name`
                        message = "- [Add] #{spec_name} #{spec_version} by #{git_user_name}"
                        commit_and_push file_path, repo_all_path, message
                    else
                        puts "ERR:: The #{spec_version} of #{spec_name} is existed."
                    end
                end
            end
        end
    end
else
    install
end

