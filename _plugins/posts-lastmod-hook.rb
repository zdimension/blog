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
        if post.data['media_subpath'].nil?
          post.data['media_subpath'] = "/assets/posts/#{clean_name}/"
        end

        if post.data['cover_responsive']
          filename = post.data["image"]
          # get base filename and extension separately
          ext = File.extname(filename)
          basename = File.basename(filename, ext)
          # puts PictureTag.source_dir
          # src_img = PictureTag::SourceImage.new(filename)
          # gen_img = PictureTag::GeneratedImage.new(
          #   source_file: img, 
          #   width: 1200, 
          #   format: PictureTag.formats.first)
          new_url = "../../../generated/assets/posts/#{clean_name}/#{basename}-800.webp"
          if ext == ".svg"
            post.data["image_seo"] = new_url
          else
            post.data["image"] = new_url
          end
          # post.data["image"] = "../../../#{gen_img.uri}"
        end

        if post.data['cover_hide']
          post.content = "<style>
          .post-meta > div.mt-3.mb-3 {
            display: none;
          }
        </style>\n" + post.content
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

      def image_hash
        @image_hash ||= begin
          if page["image_seo"]
            if page["cover_responsive"]
              image_meta = page["image_seo"]
            else
              image_meta = page['media_subpath'] + page["image_seo"]
            end
          else
            image_meta = page["image"]
          end

          case image_meta
          when Hash
            { "path" => nil }.merge!(image_meta)
          when String
            { "path" => image_meta }
          else
            { "path" => nil }
          end
        end
      end
    end
  end
end

module PictureTag
  class Picture < Liquid::Tag
    alias_method :setup_original, :setup

    def setup(context)
      @raw_params = File.join(context.environments.first["page"]["media_subpath"], @raw_params)

      setup_original(context)
    end
  end

  class GeneratedImage
    alias_method :initialize_original, :initialize

    def initialize(source_file:, width:, format:, shortfn: false)
      if width.nil?
        width = source_file.width
      end

      @shortfn = shortfn

      initialize_original(source_file: source_file, width: width, format: format)
    end

    alias_method :name_original, :name

    def name
      if @shortfn
        @name ||= "#{@source.base_name}-#{@width}.#{format}"
      else
        name_original
      end
    end
  end

  class SourceImage
    def image
      full_name = name
      # if ext is svg, add [dpi=144]
      #if ext == "svg"
      #  full_name += "[dpi=18,scale=4]"
      #end
      @image ||= Vips::Image.new_from_file(full_name)
    end
  end

  module OutputFormats
    class Basic
      alias_method :build_base_img_original, :build_base_img

      def build_base_img
        img = build_base_img_original

        if PictureTag.html_attributes['legend']
          img.title = PictureTag.html_attributes['legend'].gsub(/"/, '&quot;')
        end

        img
      end

      def add_alt(element, alt)
        element.alt = alt.gsub(/"/, '&quot;') if alt
      end

      alias_method :to_s_original, :to_s

      def to_s
        markup = to_s_original

        if PictureTag.html_attributes['legend']
          legend = DoubleTag.new 'em', content: PictureTag.html_attributes['legend'], oneline: true
          markup += legend.to_s
        end

        if PictureTag.html_attributes['hide']
          ""
        else
          markup
        end
      end

      def build_fallback_image
        return fallback_candidate if fallback_candidate.exists?

        image = GeneratedImage.new(
          source_file: PictureTag.source_images.first,
          format: PictureTag.source_images.first.ext == "svg" ? "webp" : PictureTag.fallback_format,
          width: checked_fallback_width
        )

        image.generate

        image
      end

      alias_method :checked_fallback_width_original, :checked_fallback_width

      def checked_fallback_width
        target = PictureTag.fallback_width

        if PictureTag.source_images.first.ext
          target
        else
          checked_fallback_width_original
        end
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

        gen_cover = PictureTag.html_attributes['cover']
        @target_files = target_files_original + [
          GeneratedImage.new(
            source_file: @source_image,
            width: source_width,
            format: @input_format
          )
        ] + (
          gen_cover ? [GeneratedImage.new(
            source_file: @source_image,
            width: 800,
            format: @input_format == "svg" ? "webp" : @input_format,
            shortfn: true
          )] : []
        )
      end

      def checked_targets
        if PictureTag.source_images.first.ext != "svg"
          if target_files.any? { |f| f.width > source_width }

            small_source_warn

            files = target_files.reject { |f| f.width >= source_width }
            files.push(generate_file(source_width))
          end
        end

        files || target_files
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

module AssignFilter
  def assign(obj, attr, value)
    obj.instance_variable_set("@#{attr}", value)
  end
end

Liquid::Template.register_filter(AssignFilter)

module JekyllEvalFilter
  # This Jekyll filter evaluates the input string and returns the result.
  # Use it as a calculator or one-line Ruby program evaluator.
  #
  # @param input_string [String].
  # @return [String] input string and the evaluation result.
  # @example Use like this:
  #   {{ 'TODO: show typical input' | eval }} => "TODO: show output"
  def evaluate(input_string)
    input_string.strip!
    Kernel.eval input_string.strip
  end
end

Liquid::Template.register_filter JekyllEvalFilter