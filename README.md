# scaffold
Collect some scripts 

### The cocoaPods private repo push tool  
1. 查看私有源名称。  
```pod repo list```  
其中 master 是 cocoaPods 公共源。  

2. 在终端中执行。  
```bash
$ curl -fsSL https://raw.githubusercontent.com/cloudorz/scaffold/master/private_trunk.rb -o /tmp/install.rb && ruby /tmp/install.rb && rm /tmp/install.rb
```  

3. 使用，在含有 podspec 文件目录下执行。  
```$ #{ 私有源的名称 }_trunk```  


