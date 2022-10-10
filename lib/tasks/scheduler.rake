desc "This task is called by the Heroku scheduler add-on"
task :update_feed => :environment do
  require 'line/bot'  # gem 'line-bot-api'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }

  # 使用したxmlデータ（毎日朝6時更新）：以下URLを入力すれば見ることができます。
  url  = "https://www.drk7.jp/weather/xml/13.xml"
  # xmlデータをパース（利用しやすいように整形）
  xml  = URI.open( url ).read.toutf8 # open でエラーになるときは URI.open としてみてください
  doc = REXML::Document.new(xml)
  # パスの共通部分を変数化（area[4]は「東京地方」を指定している）
  xpath = 'weatherforecast/pref/area[4]/info[1]/'
  # 天気
  weather = doc.elements[xpath + 'weather'].text
  # 気温
  maxTemp = doc.elements[xpath + 'temperature/range[1]'].text
  minTemp = doc.elements[xpath + 'temperature/range[2]'].text
  # 降水確率
  per06to12 = doc.elements[xpath + 'rainfallchance/period[2]'].text
  per12to18 = doc.elements[xpath + 'rainfallchance/period[3]'].text
  per18to24 = doc.elements[xpath + 'rainfallchance/period[4]'].text
  
  push =
      "#今日の天気は #{weather} です。\n気温\n　  最高気温　#{maxTemp}℃\n　  最低気温　#{minTemp}℃\n降水確率\n　  06〜12時　#{per06to12}％\n　  12〜18時　 #{per12to18}％\n　  18〜24時　#{per18to24}％"
    # メッセージの発信先idを配列で渡す必要があるため、userテーブルよりpluck関数を使ってidを配列で取得
    user_ids = User.all.pluck(:line_id)
    message = {
      type: 'text',
      text: push
    }
    response = client.multicast(user_ids, message)
  end
  "OK"
end