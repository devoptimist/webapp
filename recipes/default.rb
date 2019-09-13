#
# Cookbook:: webapp
# Recipe:: default
#
# Copyright:: 2019, Steve Brown
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

remote_file 'C:\elam-cli.zip' do
  source node['webapp']['elam_url']
end

remote_file 'C:\movieapp.zip' do
  source node['webapp']['movieapp_url']
end

powershell_script 'extract_elam' do
  code <<-EOH
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory('C:\\elam-cli.zip', 'C:\\elam-cli-extracted')
  EOH
  creates 'C:\elam-cli-extracted'
end

powershell_script 'extract_movieapp' do
  code <<-EOH
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory('C:\\movieapp.zip', '#{node['iis']['docroot']}/publish')
  EOH
  creates "#{node['iis']['docroot']}/publish/MovieApp.csproj.use"
end

powershell_script 'install_iis' do
  code <<-EOH
  Import-Module Servermanager
  Add-WindowsFeature Web-Server,Web-Asp-Net
  EOH
end

iis_site 'Default Web Site' do
  action %i(stop delete)
end

remote_directory "#{node['iis']['docroot']}/publish" do
  source 'publish'
  action :create
end

iis_pool 'movieapp.com_apppool' do
  runtime_version '2.0'
  action %i(add start)
end

iis_site 'movieapp.com' do
  protocol :http
  application_pool 'movieapp.com_apppool'
  port 80
  path "#{node['iis']['docroot']}/publish"
  action %i(add start)
end

powershell_script 'write_result' do
  code <<-EOH
  .\\elam-cli.exe export-iis --what-if --json > C:\\elam_out_tmp.json
  [System.IO.File]::WriteAllLines('C:\\elam_out.json', (Get-Content -Path C:\\elam_out_tmp.json))
  Remove-Item C:\\elam_out_tmp.json
  EOH
  cwd 'c:\elam-cli-extracted'
  creates 'C:\elam_out.json'
end

ruby_block 'get_result' do
  block do
    node.default['elam_discover']['output'] = JSON.parse(::File.read('C:\elam_out.json'))
  end
end

ruby_block 'get_result' do
  block do
    Chef::Log.error(node['elam_discover']['output'][0]['Name'])
  end
end
