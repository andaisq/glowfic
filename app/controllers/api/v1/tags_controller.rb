class Api::V1::TagsController < Api::ApiController
  resource_description do
    description 'Viewing tags'
  end

  api :GET, '/tags', 'Load all the tags of the specified type that match the given query'
  param :q, String, required: false, desc: "Query string"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  param :t, ['Setting', 'Label', 'ContentWarning'], required: true, desc: 'Whether to search Settings, Content Warnings or Labels'
  error 422, "Invalid parameters provided"
  def index
    queryset = params[:t].constantize.where("name LIKE ?", params[:q].to_s + '%')
    tags = paginate queryset, per_page: 25
    render json: {results: tags}
  end
end