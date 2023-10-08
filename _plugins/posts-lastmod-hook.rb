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
end