# frozen_string_literal: true

class ReplySeparator

  RULES = [
    /^-{2,10} $.*/m,
    /^>*\s*----- ?Original Message ?-----.*/m,
    /^>*\s*From:[^\r\n]*[\r\n]+Sent:.*/m,
    /^>*\s*From:[^\r\n]*[\r\n]+Date:.*/m,
    /^>*\s*-----Urspr.ngliche Nachricht----- .*/m,
    /^>*\s*Le[^\r\n]{10,200}a .crit ?:\s*$.*/,
    /^>*\s*__________________.*/m,
    /^>*\s*On.{10,200}wrote:\s*$.*/m,
    /^>*\s*Sent from my.*/m,
    /^>*\s*=== Please reply above this line ===.*/m,
    /(^>.*\n?){10,}/,
  ].freeze

  def self.separate(text)
    return "" unless text.is_a?(String)

    text = text.gsub("\r", "")
    stripped = String.new
    RULES.each do |rule|
      text.gsub!(rule) do
        stripped = ::Regexp.last_match(0).to_s + "\n" + stripped
        ""
      end
    end
    stripped = stripped.strip
    [text.strip, stripped.presence]
  end

end
