class ReleaseNotes
  def initialize(markdown: nil)
    @notes = parse_release_notes(markdown || file_content)
  end

  def latest
    @notes.first
  end

private

  def parse_release_notes(content)
    content.scan(regexp).map do |match|
      ReleaseNote.new(
        date: match[0],
        content: GovukMarkdown.render(match[1].strip),
      )
    end
  end

  def regexp
    /## (\d{1,2} [A-Za-z]+ \d{4})\n\n([^\n]+)/
  end

  def file_content
    File.read(Rails.root.join("app/views/api/guidance/release-notes.md"))
  end

  ReleaseNote = Struct.new(:date, :content, keyword_init: true)
end
