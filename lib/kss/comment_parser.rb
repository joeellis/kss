module Kss
  # Public: Takes a file path of a text file and extracts comments from it.
  # Currently accepts two formats:
  #
  # // Single line style.
  # /* Multi-line style. */
  class CommentParser

    # Returns a boolean.
    def self.single_line_comment?(line)
      !!(line =~ /\s*\/\//)
    end

    # Returns a boolean.
    def self.start_multi_line_comment?(line)
      !!(line =~ /\s*\/\*/)
    end

    # Returns a boolean.
    def self.end_multi_line_comment?(line)
      !!(line =~ /.*\*\//)
    end

    # Returns a String.
    def self.parse_single_line(line)
      matches = line.match /(.*\/\/)(.+)?/
      matches[2].to_s
    end

    # Returns a String.
    def self.parse_multi_line(line)
      cleaned = line.to_s.sub(/\s*\/\*/, '')
      cleaned = cleaned.sub(/\*\//, '')
      cleaned
    end

    # Public: Initializes a new comment parser object. Does not parse on
    # initialization.
    #
    # file_path - The location of the file to parse as a String.
    # options   - Optional options hash.
    #   :preserve_whitespace - Preserve the whitespace before/after comment
    #                          markers (default:false).
    #
    def initialize(file_path, options={})
      @options = options
      @options[:preserve_whitespace] = false if @options[:preserve_whitespace].nil?
      @file_path = file_path
      @blocks = []
      @parsed = false
    end

    # Public: The different sections of parsed comment text. A section is
    # either a multi-line comment block's content, or consecutive lines of
    # single-line comments.
    #
    # Returns an Array of parsed comment Strings.
    def blocks
      @parsed ? @blocks : parse_blocks
    end


    def parse_blocks
      File.open @file_path do |file|
        current_block = nil
        inside_single_line_block = false
        inside_multi_line_block  = false

        file.each_line do |line|
          # Parse single-line style
          if self.class.single_line_comment?(line)
            parsed = self.class.parse_single_line line
            if inside_single_line_block
              current_block += "\n#{parsed}"
            else
              current_block = parsed.to_s
              inside_single_line_block = true
            end
          end

          # Parse multi-lines tyle
          if self.class.start_multi_line_comment?(line) || inside_multi_line_block
            parsed = self.class.parse_multi_line line
            if inside_multi_line_block
              current_block += "\n#{parsed}"
            else
              current_block = parsed
              inside_multi_line_block = true
            end
          end

          # End a multi-line block if detected
          inside_multi_line_block = false if self.class.end_multi_line_comment?(line)

          # Store the current block if we're done
          unless self.class.single_line_comment?(line) || inside_multi_line_block
            @blocks << normalize(current_block) unless current_block.nil?

            inside_single_line_block = false
            current_block = nil
          end
        end
      end

      @parsed = true
      @blocks
    end

    # Normalizes the comment block to ignore any consistent preceding
    # whitespace. Consistent means the same amount of whitespace on every line
    # of the comment block. Also strips any whitespace at the start and end of
    # the whole block.
    #
    # Returns a String of normalized text.
    def normalize(text_block)
      return text_block if @options[:preserve_whitespace]

      # Strip consistent indenting by measuring first line's whitespace
      indent_size = nil
      unindented = text_block.split("\n").collect do |line|
        preceding_whitespace = line.scan(/^\s*/)[0].to_s.size
        indent_size = preceding_whitespace if indent_size.nil?
        if line == ""
          ""
        elsif indent_size <= preceding_whitespace
          line.slice(indent_size, line.length - 1)
        else
          line
        end
      end.join("\n")

      unindented.strip
    end

  end
end