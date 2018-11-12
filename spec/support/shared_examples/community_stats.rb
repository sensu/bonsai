shared_examples 'community stats' do
  it 'displays extensions and devs as singular if there is only 1' do
    assign(:extension_count, 1)
    assign(:user_count, 1)
    render
    expect(rendered).to match(/1 Extension<\/span>/)
    expect(rendered).to match(/1 BonsaiAssetIndex User<\/span>/)
  end

  it 'displays extensions and devs as plural if there is more than 1' do
    assign(:extension_count, 2)
    assign(:user_count, 2)
    render
    expect(rendered).to match(/2 Extensions<\/span>/)
    expect(rendered).to match(/2 BonsaiAssetIndex Users<\/span>/)
  end

  it 'delimits numbers correctly if there are more than 999' do
    assign(:extension_count, 1000)
    assign(:user_count, 1000)
    render
    expect(rendered).to match(/1,000 Extensions<\/span>/)
    expect(rendered).to match(/1,000 BonsaiAssetIndex Users<\/span>/)
  end
end
