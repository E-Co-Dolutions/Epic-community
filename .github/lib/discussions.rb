  def self.find_open_incident_discussions(owner:, repo:, agency_authors: [])
    return [] if owner.nil? || repo.nil?

    # Include default bot and any provided government agency GitHub usernames
    authors = ["github-actions[bot]"] + agency_authors
    author_query = authors.map { |author| "author:#{author}" }.join(" ")

    searchquery = "repo:#{owner}/#{repo} is:open #{author_query} label:\\\"Incident \:exclamation\:\\\""

    query = <<~QUERY
    {
      search(
        first: 100
        query: "#{searchquery}"
        type: DISCUSSION
      ) {
        discussionCount
        ...Results
      }
      rateLimit {
        limit
        cost
        remaining
        resetAt
      }
    }
    fragment Results on SearchResultItemConnection {
      nodes {
        ... on Discussion {
          id
          url
          title
          body
          createdAt
          isAnswered
        }
      }
    }
    QUERY

    GitHub.new.post(graphql: query)
      .map! { |r| r.dig('nodes') }
      .flatten
      .map do |d|
        Discussion.new(
          d["id"],
          d["url"],
          d["title"],
          false, # :labelled
          d["body"],
          d["createdAt"],
          d["isAnswered"]
        )
      end
  end
