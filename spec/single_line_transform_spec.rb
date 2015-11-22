require 'buffering_logger/single_line_transform'

describe BufferingLogger::SingleLineTransform do

  it 'strips the string, replaces newlines with spaces and adds a newline at the end' do
    transform = BufferingLogger::SingleLineTransform.new
    string = " one\r\ntwo\nthree \n"
    expect(transform.call(string)).to eq("one two three\n")
  end

  context 'with a custom replacement' do
    it 'replaces newlines with the replacement' do
      transform = BufferingLogger::SingleLineTransform.new(
        replacement: ' ::nl:: ',
      )
      string = " one\ntwo\nthree \n"
      expect(transform.call(string)).to eq("one ::nl:: two ::nl:: three\n")
    end
  end
end
