= これは何?
howmに登録したイベントの中で現在より新しくてステータスが"@"か"!"になっているものをGoogle Calendarに投げる代物です。


= ビルド
opamでomakeとgapi-ocamlとconfig-fileなどをinstallしてomakeしてビルドします。

= セットアップ
Google Developers Consoleにアプリケーションを新たに登録してAPIメニューからCalendarを有効にしてください。
次にカレントディレクトリに"config.txt"というファイルを用意して以下の様に記述してください。

'''
app_name = "<your_app_name>"
client_id = "<your_client_id>"
client_secret = "<your_client_secret>"
redirect_uri = "<your_redirect_uri>"
howm_root = "<your_howm_root_path>"
'''

アプリケーションを起動すると、認証用URLが表示されるのでブラウザで開いて認証してください。
認証後のリダイレクト先のURLのcodeの部分をコピーして端末に貼り付けたら認証が完了する筈です。

次回以降の起動では認証が終わった状態になります。

= 使う
認証してからもう一度起動するとhowmのディレクトリを走査して今日以降のイベントでフラグが"@"か"!"になっているものをすべてGoogle Calendarに投げます。

以上
