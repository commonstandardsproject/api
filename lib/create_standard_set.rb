class CreateStandardSet

  def self.create(params)

    jurisdiction = $db[:jurisdictions].find({_id: params[:jurisdiction_id]}).to_a.first

    doc = {
      :_id => SecureRandom.uuid().to_s.gsub("-", "").upcase,
      :jurisdiction => {
        :id    => params[:jurisdiction_id],
        :title => jurisdiction[:title]
      },
      :title => params[:title],
      :subject => params[:subject],
      :educationLevels => [],
      :license => {
        :title        => "CC BY 4.0 US",
        :URL          => "http://creativecommons.org/licenses/by/4.0/us/",
        :rightsHolder => "Common Curriculum, Inc."
      },
      :status => "in-review",
      :commit => {
        :name  => params[:committerName],
        :email => params[:committerEmail],
        :date  => Time.now
      }
    }

    $db[:standard_sets].insert_one(doc)

    doc
  end

end
