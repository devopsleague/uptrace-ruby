# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'
require 'action_controller/railtie'
require 'opentelemetry-instrumentation-rails'
require 'uptrace'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Rails'

  c.service_name = 'myservice'
  c.service_version = '1.0.0'

  # copy your project DSN here or use UPTRACE_DSN env var
  Uptrace.configure_opentelemetry(c, dsn: '')
end

# TraceRequestApp is a minimal Rails application inspired by the Rails
# bug report template for action controller.
# The configuration is compatible with Rails 6.0
class TraceRequestApp < Rails::Application
  config.root = __dir__
  config.hosts << 'example.org'
  secrets.secret_key_base = 'secret_key_base'
  config.eager_load = false
  config.logger = Logger.new($stdout)
  Rails.logger  = config.logger

  routes.append do
    get '/', to: 'example#index'
    get '/profiles/:username', to: 'example#profile', as: 'profile'
  end
end

class ExampleController < ActionController::Base
  include Rails.application.routes.url_helpers

  def index
    trace_url = Uptrace.trace_url()
    render inline: %(
      <html>
        <p>Here are some routes for you:</p>
        <ul>
          <li><%= link_to 'Hello world', profile_path(username: 'world') %></li>
          <li><%= link_to 'Hello foo-bar', profile_path(username: 'foo-bar') %></li>
        </ul>
        <p><a href="#{trace_url}">#{trace_url}</a></p>
      </html>
    )
  end

  def profile
    trace_url = Uptrace.trace_url()
    render inline: %(
      <html>
        <h3>Hello #{params[:username]}</h3>
        <p><a href="#{trace_url}">#{trace_url}</a></p>
      </html>
    )
  end
end

Rails.application.initialize!

run Rails.application
