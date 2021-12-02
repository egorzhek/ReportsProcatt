Выложил job образ:
1. docker pull yefimenkolya/jobproject
2. Создать папку /c/Work/jobproject
3. Настроить файл appsettings.json
4. docker run -d -it --rm -v "/c/Work/jobproject":/work  -e SettingsPath=/work/ --name jobproject yefimenkolya/jobproject

В БД должна быть реализована процедура dbo.app_RefreshAssets