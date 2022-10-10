class LinebotController < ApplicationController
  require 'line/bot'  # gem 'line-bot-api'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      return head :bad_request
    end
    events = client.parse_events_from(body)
    events.each { |event|
      case event
        # メッセージが送信された場合の対応（機能①）
      when Line::Bot::Event::Message
        case event.type
          # ユーザーからテキスト形式のメッセージが送られて来た場合
        when Line::Bot::Event::MessageType::Text
          # event.message['text']：ユーザーから送られたメッセージ
          input = event.message['text']
          url  = xmlurlByPrefecture(input)
          xml  = URI.open(url).read.toutf8 # open でエラーになるときは URI.open としてみてください
          doc = REXML::Document.new(xml)
          pref = doc.elements['weatherforecast/pref'].attributes['id']
          xpath = 'weatherforecast/pref/area[1]/'
          
          case input
          when /.*(今日|きょう).*/
            push = wheatherData(doc, xpath + 'info[1]', pref)
          when /.*(明日|あした|あす).*/
            push = wheatherData(doc, xpath + 'info[2]', pref)
          when /.*(明後日|あさって).*/
            push = wheatherData(doc, xpath + 'info[3]', pref)

          when /.*(かわいい|可愛い|カワイイ|きれい|綺麗|キレイ|素敵|ステキ|すてき|面白い|おもしろい|ありがと|すごい|スゴイ|スゴい|好き|頑張|がんば|ガンバ).*/
            push =
              "ありがとう！！！\n優しい言葉をかけてくれるあなたはとても素敵です。"
          when /.*(こんにちは|こんばんは|初めまして|はじめまして|おはよう).*/
            push =
              "こんにちは。\n声をかけてくれてありがとう\n今日があなたにとっていい日になりますように。"
          else
            push = "「今日」「明日」「明後日」のメッセージでそれぞれの天気をお知らせします。"
          end
          # テキスト以外（画像等）のメッセージが送られた場合
        else
            push = "「今日」「明日」「明後日」のメッセージでそれぞれの天気をお知らせします。"
        end
        message = {
          type: 'text',
          text: push
        }
        client.reply_message(event['replyToken'], message)
        # LINEお友達追された場合（機能②）
      when Line::Bot::Event::Follow
        # 登録したユーザーのidをユーザーテーブルに格納
        line_id = event['source']['userId']
        User.create(line_id: line_id)
        # LINEお友達解除された場合（機能③）
      when Line::Bot::Event::Unfollow
        # お友達解除したユーザーのデータをユーザーテーブルから削除
        line_id = event['source']['userId']
        User.find_by(line_id: line_id).destroy
      end
    }
    head :ok
  end

  private

    def client
      @client ||= Line::Bot::Client.new { |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      }
    end

    def xmlurlByPrefecture(input)
      case input
      when /.*(北海道|ほっかいどう).*/
        return "https://www.drk7.jp/weather/xml/01.xml"
      when /.*(青森|あおもり).*/
        return "https://www.drk7.jp/weather/xml/02.xml"
      when /.*(岩手|いわて).*/
        return "https://www.drk7.jp/weather/xml/03.xml"
      when /.*(宮城|みやぎ).*/
        return "https://www.drk7.jp/weather/xml/04.xml"
      when /.*(秋田|あきた).*/
        return "https://www.drk7.jp/weather/xml/05.xml"
      when /.*(山形|やまがた).*/
        return "https://www.drk7.jp/weather/xml/06.xml"
      when /.*(福島|ふくしま).*/
        return "https://www.drk7.jp/weather/xml/07.xml"
      when /.*(茨城県|いばらき).*/
        return "https://www.drk7.jp/weather/xml/08.xml"
      when /.*(栃木|とちぎ).*/
        return "https://www.drk7.jp/weather/xml/09.xml"
      when /.*(群馬|ぐんま).*/
        return "https://www.drk7.jp/weather/xml/10.xml"
      when /.*(埼玉|さいたま).*/
        return "https://www.drk7.jp/weather/xml/11.xml"
      when /.*(千葉|ちば).*/
        return "https://www.drk7.jp/weather/xml/12.xml"
      when /.*(東京|とうきょう).*/
        return "https://www.drk7.jp/weather/xml/13.xml"
      when /.*(神奈川|かながわ).*/
        return "https://www.drk7.jp/weather/xml/14.xml"
      when /.*(新潟|にいがた).*/
        return "https://www.drk7.jp/weather/xml/15.xml"
      when /.*(富山|とやま).*/
        return "https://www.drk7.jp/weather/xml/16.xml"
      when /.*(石川|いしかわ).*/
        return "https://www.drk7.jp/weather/xml/17.xml"
      when /.*(福井|ふくい).*/
        return "https://www.drk7.jp/weather/xml/18.xml"
      when /.*(山梨|やまなし).*/
        return "https://www.drk7.jp/weather/xml/19.xml"
      when /.*(長野|ながの).*/
        return "https://www.drk7.jp/weather/xml/20.xml"
      when /.*(岐阜|ぎふ).*/
        return "https://www.drk7.jp/weather/xml/21.xml"
      when /.*(静岡|しずおか).*/
        return "https://www.drk7.jp/weather/xml/22.xml"
      when /.*(愛知|あいち).*/
        return "https://www.drk7.jp/weather/xml/23.xml"
      when /.*(三重|みえ).*/
        return "https://www.drk7.jp/weather/xml/24.xml"
      when /.*(滋賀|しが).*/
        return "https://www.drk7.jp/weather/xml/25.xml"
      when /.*(京都|きょうと).*/
        return "https://www.drk7.jp/weather/xml/26.xml"
      when /.*(大阪|おおさか).*/
        return "https://www.drk7.jp/weather/xml/27.xml"
      when /.*(兵庫|ひょうご).*/
        return "https://www.drk7.jp/weather/xml/28.xml"
      when /.*(奈良|なら).*/
        return "https://www.drk7.jp/weather/xml/29.xml"
      when /.*(和歌山|わかやま).*/
        return "https://www.drk7.jp/weather/xml/30.xml"
      when /.*(鳥取|とっとり).*/
        return "https://www.drk7.jp/weather/xml/31.xml"
      when /.*(島根|しまね).*/
        return "https://www.drk7.jp/weather/xml/32.xml"
      when /.*(岡山|おかやま).*/
        return "https://www.drk7.jp/weather/xml/33.xml"
      when /.*(広島|ひろしま).*/
        return "https://www.drk7.jp/weather/xml/34.xml"
      when /.*(山口|やまぐち).*/
        return "https://www.drk7.jp/weather/xml/35.xml"
      when /.*(徳島|とくしま).*/
        return "https://www.drk7.jp/weather/xml/36.xml"
      when /.*(香川|かがわ).*/
        return "https://www.drk7.jp/weather/xml/37.xml"
      when /.*(愛媛|えひめ).*/
        return "https://www.drk7.jp/weather/xml/38.xml"
      when /.*(高知|こうち).*/
        return "https://www.drk7.jp/weather/xml/39.xml"
      when /.*(福岡|ふくおか).*/
        return "https://www.drk7.jp/weather/xml/40.xml"
      when /.*(佐賀|さが).*/
        return "https://www.drk7.jp/weather/xml/41.xml"
      when /.*(長崎|長崎).*/
        return "https://www.drk7.jp/weather/xml/42.xml"
      when /.*(熊本|くまもと).*/
        return "https://www.drk7.jp/weather/xml/43.xml"
      when /.*(大分|おおいた).*/
        return "https://www.drk7.jp/weather/xml/44.xml"
      when /.*(宮崎|みやざき).*/
        return "https://www.drk7.jp/weather/xml/45.xml"
      when /.*(鹿児島|かごしま).*/
        return "https://www.drk7.jp/weather/xml/46.xml"
      when /.*(沖縄|おきなわ).*/
        return "https://www.drk7.jp/weather/xml/47.xml"
      else
        return "https://www.drk7.jp/weather/xml/13.xml"
      end
    end

    def wheatherData(doc, dateNode, pref)
      date = doc.elements[dateNode].attributes['date']
      weather = doc.elements[dateNode + '/weather'].text
      maxTemp = doc.elements[dateNode + '/temperature/range[1]'].text
      minTemp = doc.elements[dateNode + '/temperature/range[2]'].text

      per06to12 = doc.elements[dateNode + '/rainfallchance/period[2]'].text
      per12to18 = doc.elements[dateNode + '/rainfallchance/period[3]'].text
      per18to24 = doc.elements[dateNode + '/rainfallchance/period[4]'].text
      return "#{date} #{pref}\n天気\n　  #{weather}\n気温\n　  最高気温　#{maxTemp}℃\n　  最低気温　#{minTemp}℃\n降水確率\n　  06〜12時　#{per06to12}％\n　  12〜18時　 #{per12to18}％\n　  18〜24時　#{per18to24}％"
    end
end
