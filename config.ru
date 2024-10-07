# frozen_string_literal: true

require './config/application'

run(Routes::Application.freeze.app)
