namespace :db do
  namespace :clear do
    desc 'Remove all votes.'
    task :votes => :environment do
      Vote.destroy_all
    end

    desc 'Remove all representatives'
    task :representatives => :environment do
      Representative.destroy_all
    end

    desc 'Remove all promises'
    task :promises => :environment do
      Promise.destroy_all
    end

    desc 'Remove all issues'
    task :issues => :environment do
      Issue.destroy_all
    end
  end

  namespace :dump do
    task :issues => :environment do
      data = Issue.all.map { |issue|
        i = issue.as_json

        # not mass-assignable
        i.delete('created_at')
        i.delete('updated_at')
        i.delete('slug')
        i.delete('id')

        i['topic_names']          = issue.topics.map { |e| e.name }
        i['category_external_ids'] = issue.categories.map { |e| e.external_id }
        i['promise_external_ids'] = issue.promises.map { |e| e.external_id }
        i['vote_connections']     = issue.vote_connections.map do |e|
          {
            :vote_external_id => e.vote.external_id,
            :weight           => e.weight,
            :comment          => e.comment,
            :description      => e.description,
            :matches          => e.matches?
          }
        end

        i
      }

      out = "issues.json"
      File.open(out, "w") { |io| io << data.to_json }

      puts "wrote #{out}"
    end

    task :users => :environment do
      data = User.all.as_json(:methods => :encrypted_password)

      out = "users.json"
      File.open(out, "w") { |io| io << data.to_json }

      puts "wrote #{out}"
    end
  end

  namespace :load do
    task :issues => :environment do
      file = ENV['FILE'] or raise "must set FILE"
      data = MultiJson.decode(open(file).read)

      data.each do |hash|
        topics = hash.delete('topic_names').map { |name| Topic.find_by_name!(name) }
        promises = hash.delete('promise_external_ids').map { |id| Promise.find_by_external_id!(id) }
        categories = hash.delete('category_external_ids').map { |id| Category.find_by_external_id!(id) }
        vote_connections = hash.delete('vote_connections')

        issue = Issue.create(hash)

        issue.categories = categories
        issue.topics     = topics
        issue.promises   = promises

        issue.save!

        vote_connections.each do |conn|
          vote_id     = Vote.find_by_external_id!(conn.fetch('vote_external_id')).id
          weight      = conn.fetch('weight')
          description = conn.fetch('description')
          comment     = conn.fetch('comment')
          matches     = conn.fetch('matches')

          issue.vote_connections.create!(
            :vote_id     => vote_id,
            :weight      => weight,
            :description => description,
            :comment     => comment,
            :matches     => matches
          )
        end

      end
    end

    task :users => :environment do
      file = ENV['FILE'] or raise "must set FILE"
      data = MultiJson.decode(open(file).read)

      data.each do |hash|
        sql = <<-SQL
          INSERT INTO users (
            created_at,
            updated_at,
            email,
            name,
            encrypted_password
          ) VALUES (?, ?, ?, ?, ?)
        SQL

        sql = ActiveRecord::Base.send :sanitize_sql_array, [
          sql,
          hash.fetch('created_at'),
          hash.fetch('updated_at'),
          hash.fetch('email'),
          hash.fetch('name'),
          hash.fetch('encrypted_password')
        ]

        ActiveRecord::Base.connection.execute sql
      end

    end
  end
end
