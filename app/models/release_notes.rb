class ReleaseNotes
  def initialize(markdown: nil)
    @notes = parse_release_notes(markdown || content)
  end

  def latest
    @notes.first
  end

private

  def parse_release_notes(content)
    content.scan(regexp).map do |match|
      ReleaseNote.new(
        date: match[0],
        content: match[1].strip,
      )
    end
  end

  def regexp
    /^## (.*?)\n\n(.*?)(?=\n##|\z)/m
  end

  def content
    File.read(Rails.root.join("release_notes.md"))
  end

  ReleaseNote = Struct.new(:date, :content, keyword_init: true)
end
