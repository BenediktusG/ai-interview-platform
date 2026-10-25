# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authentication API', type: :request do
  describe 'POST /api/v1/auth/signup (DEF-P1-05)' do
    let(:valid_params) do
      {
        email: 'recruiter.monozukuri@rakamin.com',
        password: 'secure_password_123',
        role: 'user'
      }
    end

    it 'creates a new user and returns JWT token with user object' do
      post '/api/v1/auth/signup', params: valid_params, as: :json

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['token']).to be_present
      expect(json['user']['email']).to eq('recruiter.monozukuri@rakamin.com')
      expect(json['user']['role']).to eq('user')
    end

    it 'rejects request with missing email or password' do
      post '/api/v1/auth/signup', params: { email: '', password: '' }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Email and password are required')
    end

    it 'rejects registration when email is already taken' do
      User.create!(
        email: 'recruiter.monozukuri@rakamin.com',
        password: 'existing_password',
        role: 'user'
      )

      post '/api/v1/auth/signup', params: valid_params, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Email has already been taken')
    end
  end

  describe 'POST /api/v1/auth/login' do
    let!(:user) do
      User.create!(
        email: 'lead.assessor@rakamin.com',
        password: 'password123',
        role: 'user'
      )
    end

    it 'authenticates valid credentials and returns JWT token' do
      post '/api/v1/auth/login', params: { email: 'lead.assessor@rakamin.com', password: 'password123' }, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['token']).to be_present
      expect(json['user']['id']).to eq(user.id)
    end

    it 'rejects invalid credentials with 401 unauthorized' do
      post '/api/v1/auth/login', params: { email: 'lead.assessor@rakamin.com', password: 'wrongpassword' }, as: :json

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Invalid email or password')
    end
  end
end
