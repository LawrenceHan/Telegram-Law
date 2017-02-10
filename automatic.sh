echo "项目根目录下config.h配置APPID和HASH，文件内有说明"

echo "本项目使用了submodule进行管理接下来更新子项目"
echo "由于未知原因，子项目的SSH方式访问失败，所以更改项目访问方式为HTTPS"

echo "更新子项目..."

git submodule init
git submodule update --checkout
git submodule update

