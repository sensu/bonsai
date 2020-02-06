require 'spec_helper'

describe Api::V1::TagsController do

  describe 'GET #index' do

  	before do
      Tag::DEFAULT_TAGS.each do |name|
      	Tag.new(name: name)
      end
    end

  	context 'with a query string' do

  		before do
        get :index,
            params: {q: 'ala'},
            format: :json
        @data = JSON.parse(response.body)
      end

      it 'succeeds' do
        expect(response).to be_successful
        expect(@data).to be_a(Array)
      end

      it 'includes the default tag' do
        expect(@data).to include('alarms')
      end
  	end

  	context 'with a query of irregular characters' do

      it 'succeeds' do
      	get :index,
            params: {q: 'ala['},
            format: :json
        @data = JSON.parse(response.body)
        expect(response).to be_successful
        expect(@data).to be_a(Array)
        expect(@data).to include('alarms')
      end

      it 'succeeds with no results' do
        get :index,
            params: {q: '%5C'},
            format: :json
        @data = JSON.parse(response.body)
        expect(response).to be_successful
        expect(@data).to be_a(Array)
        expect(@data).to eq([])
      end
  	end

  end # get index

end

