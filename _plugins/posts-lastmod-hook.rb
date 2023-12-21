#!/usr/bin/env ruby
#
# Check for changed posts

Jekyll::Hooks.register :posts, :post_init do |post|

  commit_num = `git rev-list --count HEAD "#{ post.path }"`

  if commit_num.to_i > 1
    lastmod_date = `git log -1 --pretty="%ad" --date=iso "#{ post.path }"`
    post.data['last_modified_at'] = lastmod_date
  end

end

module Jekyll
  class PermalinkRewriter < Generator
    safe true
    priority :low

    def generate(site)
      site.posts.docs.each do |post|
        clean_name = post.basename_without_ext.gsub(/^\/|\/$/, '')
        post.data['clean_name'] = clean_name
        if post.data['img_path'].nil?
          post.data['img_path'] = "/assets/posts/#{clean_name}/"
        end

        # name_without_date = clean_name.gsub(/^\d{4}-\d{2}-\d{2}-/, '')
        # if post.data['permalink'] == '/:title/'
        #   post.data['permalink'] = "/#{name_without_date}/"
        # end
      end
    end
  end

  class SeoTag
    class ImageDrop
      def alt
        @alt ||= filters.strip_html(image_hash['alt']) if image_hash['alt']
      end
    end
  end
end

module PictureTag
  class Picture < Liquid::Tag
    alias_method :setup_original, :setup

    def setup(context)
      @raw_params = File.join(context.environments.first["page"]["img_path"], @raw_params)

      setup_original(context)
    end
  end

  module OutputFormats
    class Basic
      alias_method :wrap_original, :wrap

      def wrap2(markup)
        markup = wrap_original(markup)

        if PictureTag.html_attributes['legend']
          legend = DoubleTag.new 'em', content: PictureTag.html_attributes['legend'], oneline: true
          container = DoubleTag.new 'figure'
          container.content = markup
          container.content << legend

          markup = container
          markup = nomarkdown_wrapper(markup.to_s) if PictureTag.nomarkdown?
        end

        markup
      end

      alias_method :to_s_original, :to_s

      def to_s
        markup = to_s_original

        if PictureTag.html_attributes['legend']
          legend = DoubleTag.new 'em', content: PictureTag.html_attributes['legend'], oneline: true
          markup += legend.to_s
        end

        markup
      end
    end
  end

  module Srcsets
    class Basic
      alias_method :target_files_original, :target_files

      def target_files
        if @target_files
          return @target_files
        end

        @target_files = target_files_original + [generate_file(source_width)] 
      end
    end
  end

  module Parsers
    class HTMLAttributeSet
      def handle_source_url
        return unless PictureTag.preset['link_source'] && self['link'].nil?

        img = PictureTag.source_images.first
        gen_img = GeneratedImage.new(source_file: img, width: img.width, format: PictureTag.formats.first)

        @attributes['link'] = gen_img.uri
      end
    end
  end
end