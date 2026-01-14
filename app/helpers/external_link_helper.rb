module ExternalLinkHelper
  def external_link_to(link_text, link_key = nil, **kwargs, &block)
    if block_given?
      url = ExternalLink.fetch(link_text).url
      govuk_link_to url, **kwargs, &block
    else
      url = ExternalLink.fetch(link_key).url
      govuk_link_to link_text, url, **kwargs
    end
  end
end
