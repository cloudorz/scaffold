#!/usr/bin/env ruby 

exec_file_name = File.basename $0
exec_ext_name = File.extname $0
exec_name = File.basename($0, exec_ext_name)

puts exec_file_name
exit

private_source_name = ARGV.first
if private_source_name.nil? or private_source_name.empty?
    if exec_ext_name.empty?
        puts "Usage: #{exec_file_name} '<private repo name>'"
    else
        puts "Usage: #{exec_file_name} '<private repo name>' or 'install'"
    end
else
    if exec_ext_name == ".rb" and private_source_name == "install"
       require 'fileutils' 
       FileUtils.install $0, "/usr/local/bin/#{exec_name}", :mode => 0755, :verbose => true
    else
        # Get podsec file path
        podspec_file_path = Dir.glob("./*.podspec").first
        if podspec_file_path.nil? or podspec_file_path.empty?
            puts "ERR: podspec file does not exist."
        else
            # update private source repo
            update_result = `pod repo update #{private_source_name}`
            puts update_result
            if update_result.start_with? "[!] Unable to find the"
                puts "ERR: The '#{private_source_name}' is not existed. Use 'pod repo add <name> <repo url>' to add it."
            else
                # Parse podspec file to json
                podspec_json_string = `pod ipc spec #{podspec_file_path}`

                require 'json'
                podspec_json = JSON.parse podspec_json_string
                if podspec_json.nil?
                    puts "ERR: Parse podspec json string fail."
                else
                    # Get spec name and version
                    spec_name = podspec_json["name"]
                    spec_version = podspec_json["version"]
                    repo_dir = File.join(Dir.home, ".cocoapods", "repos", private_source_name)
                    repo_all_path = File.join(repo_dir, "Specs", spec_name, spec_version)
                    if Dir.exist? repo_all_path 
                        puts "ERR: The #{spec_version} of #{spec_name} is existed."
                    else
                        require 'fileutils'
                        FileUtils.mkdir_p repo_all_path
                        FileUtils.cp podspec_file_path, repo_all_path
                        FileUtils.cd(repo_dir) do
                            git_user_name = `git config user.name`
                            `git add . && git commit -m"- [Add] #{spec_name} #{spec_version} by #{git_user_name} && git push"`
                        end
                    end
                end
            end
        end
    end
end

