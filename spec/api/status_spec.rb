require 'spec_helper'

describe 'GET /status' do
  it 'returns a 200' do

    pending
    get status_path

    expect(response.status.to_i).to eql(200)
  end

  it 'returns a status ok' do

    pending
    get status_path

    expect(json_body).to include('status' => 'ok')
  end
end
