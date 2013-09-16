require File.dirname(__FILE__) + '/../spec_helper'

describe AssetsController do
  fixtures :assets, :users
  
  subject do
    request.env["HTTP_ACCEPT"] = "audio/mpeg" 
    get :show, :id => 'song1', :user_id => users(:sudara).login, :format => :mp3
  end
  
  GOOD_USER_AGENTS = [
    "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en) AppleWebKit/XX (KHTML, like Gecko) Safari/YY",
    "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8) Gecko/20060319 Firefox/2.0",
    "iTunes/x.x.x",
    "Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 6.0)",
    "msie",
    'webkit'
    ]
    
  BAD_USER_AGENTS = [
    "Mp3Bot/0.1 (http://mp3realm.org/mp3bot/)",
    "",
    "Googlebot/2.1 (+http://www.google.com/bot.html)",
    "you're momma's so bot...",
    "Baiduspider+(+http://www.baidu.jp/spider/)",
    "baidu/Nutch-1.0 "
  ]
  
  GOOD_USER_AGENTS.each do |agent|
    it "should register a listen for #{agent}" do
      request.user_agent = agent
      expect{ subject }.to change(Listen, :count).by(1)  
    end
  end
  
  BAD_USER_AGENTS.each do |agent|
    it "should not register a listen for #{agent}" do
      request.user_agent = agent
      expect{ subject }.should_not change(Listen, :count).by(1)  
    end
  end
  
  
  it 'should accept a mp3 extension and redirect to the amazon url' do
    request.env["HTTP_ACCEPT"] = "audio/mpeg" 
    request.user_agent = GOOD_USER_AGENTS.first
    subject
    response.should redirect_to(assets(:valid_mp3).mp3.url)
  end
  
  it 'should have a landing page' do
    request.user_agent = GOOD_USER_AGENTS.first
    get :show, :id => 'song1', :user_id => users(:sudara).login
    assigns(:assets).should be_present
    response.response_code.should == 200
  end

  it 'should properly detect leeching blacklisted sites and not register a listen' do
    request.user_agent = 'mp3bot'
    expect{ subject }.not_to change(Listen, :count)
    response.response_code.should == 403
  end

  it 'should consider an empty user agent to be a spider and not register a listen' do
    request.user_agent = ''
    expect{ subject }.not_to change(Listen, :count)
  end
  
  it 'should consider any user agent with BOT in its string a bot and not register a listen' do
    request.user_agent = 'bot'
    expect{ subject }.not_to change(Listen, :count)    
  end
  

end
