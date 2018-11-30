json.start @start
json.total @total

if @next_page_params
  json.next  api_v1_extensions_url(@next_page_params)
end

json.extensions @extensions, partial: 'extension', as: :extension
