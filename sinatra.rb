#!/usr/bin/env ruby

require 'pg'
require 'sinatra'

use Rack::Session::Pool, :expire_after => 2592000

class User
  attr_accessor :username, :name, :email, :password, :sex

  def initialize
    @username = ''
    @name = ''
    @email = ''
    @password = ''
    @sex = ''
  end

  def clean(attr)
    if attr.nil?
      ''
    else
      attr.squeeze(' ').strip.gsub(/[<]/, '&gt;')
    end
  end

  def is_valid?
    @username = clean(@username)
    @name = clean(@name)
    @email = clean(@email)
    @password = clean(@password)
    @sex = clean(@sex).downcase

    @sex = @sex == 'm' ? 'm' : 'f'

    not to_ary.select { |e| e.empty? }.empty?
  end

  def to_ary
    [@username, @email, @name, @sex, @password]
  end
end

get '/' do
  conn = PG.connect(dbname: 'cs522')
  erb :index, locals: {
    users: conn.exec('SELECT * FROM users')
  }
end

get '/delete/:id' do |id|
  conn = PG.connect( dbname: 'cs522' )
  erb :delete, locals: {
    result: conn.exec_params('delete from users where id = $1::int', [id])
  }
end

get '/add' do
  session[:user] ||= User.new
  p session[:user].inspect
  erb :add, locals: { user: session[:user] }
end

post '/add' do
  session[:user] = User.new
  session[:user].username = params['username']
  session[:user].email = params['email']
  session[:user].name = params['name']
  session[:user].password = params['password']
  session[:user].sex = params['sex']

  redirect to('/add') if session[:user].is_valid?

  p 'user is valid!'

  # if user valid
  conn = PG.connect(dbname: 'cs522')
  conn.exec_params('insert into users values (DEFAULT, $1::text, $2::text, $3::text, $4::char, $5::text)',
    session[:user].to_ary)

  session[:user] = nil
  redirect to('/')

  # erb :add, locals: { user: session[:user] }
end
