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


powershell_script 'install_iis' do
  code <<-EOH
  $ProgressPreference = 'SilentlyContinue'
  & Import-Module Servermanager >> C:\\help.log
  & Add-WindowsFeature Web-Server,Web-Asp-Net >> C:\\help.log
  EOH
end

iis_site 'Default Web Site' do
  action %i(stop delete)
end

if node['webapp']['install_app']

  remote_file 'C:\movieapp.zip' do
    source node['webapp']['app_url']
  end

  powershell_script 'extract_movieapp' do
    code <<-EOH
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory('C:\\movieapp.zip', '#{node['iis']['docroot']}')
    EOH
    creates "#{node['iis']['docroot']}\\publish\\MovieApp.csproj.user"
  end

  iis_pool 'movieapp.com_apppool' do
    runtime_version '2.0'
    action %i(add start)
  end

  iis_site 'movieapp.com' do
    protocol :http
    application_pool 'movieapp.com_apppool'
    port 80
    path "#{node['iis']['docroot']}\\publish"
    action %i(add start)
  end
end
