module Hdo
  module Search
    #
    # Module used to share ES config among models (indeces)
    #

    module Settings
      LOCALE = {
        nb: {
          language: 'Norwegian',
          stopwords: %w[at av da de den der deres det disse eller en er et for hvis i ikke inn med men nei og slik som til var vil].join(',')
        }
      }

      module_function

      def default
        @default ||= {
          analysis: {
            analyzer: {
              hdo_analyzer: {
                alias: %w[default_index],
                type: 'custom',
                tokenizer: 'standard',
                filter: default_filters
              },
              hdo_search: {
                alias: %w[default_search],
                type: 'custom',
                tokenizer: 'standard',
                # don't decompound words in the queries
                filter: default_filters - %w[hdo_decompounder]
              }
            },
            filter: {
              hdo_snowball: {
                type: 'snowball',
                language: locale.fetch(:language)
              },
              hdo_stop: {
                type: 'stop',
                stopwords: locale.fetch(:stopwords)
              },
              hdo_decompounder: {
                type: 'dictionary_decompounder',
                word_list_path: '/usr/share/dict/norsk'
              }
            }
          }
        }.with_indifferent_access
      end

      def default_analyzer
        'hdo_analyzer'
      end

      def default_filters
        %w[standard lowercase hdo_stop hdo_snowball hdo_decompounder]
      end

      def locale
        @locale ||= LOCALE.fetch(I18n.locale)
      end

    end
  end
end
