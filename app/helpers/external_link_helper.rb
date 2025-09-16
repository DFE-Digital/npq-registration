module ExternalLinkHelper
  def external_link_to(a, b = nil, **kwargs, &block)
    if block_given?
      url = ExternalLink.fetch(a).url
      govuk_link_to url, **kwargs, &block
    else
      url = ExternalLink.fetch(b).url
      govuk_link_to a, url, **kwargs
    end
  end
end
