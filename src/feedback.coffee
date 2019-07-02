scoring = require('./scoring')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      "用几句话，避免常用短语"
      "不需要符号，数字或大写字母"
    ]

  get_feedback: (score, sequence) ->
    # starting feedback
    return @default_feedback if sequence.length == 0

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = '添加1个或2个单词，最好是不常用的单词'
    if feedback?
      feedback.suggestions.unshift extra_feedback
      feedback.warning = '' unless feedback.warning?
    else
      feedback =
        warning: ''
        suggestions: [extra_feedback]
    feedback

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          '直线按键很容易猜到'
        else
          '短键盘模式很容易猜到'
        warning: warning
        suggestions: [
          '使用更长的键盘图案和更多的转弯'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          '像“aaa”这样的重复很容易猜到'
        else
          '像“abcabcabc”这样的重复只比“abc”稍微难以猜测'
        warning: warning
        suggestions: [
          '避免重复的单词和字符'
        ]

      when 'sequence'
        warning: "像abc或6543这样的序列很容易猜到"
        suggestions: [
          '避免有序字符'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: "当前年份很容易猜到"
          suggestions: [
            '避免当前年份'
            '避免与你相关的日期'
          ]

      when 'date'
        warning: "日期通常很容易猜到"
        suggestions: [
          '避免与您相关的日期和年份'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          '这是十大常用密码'
        else if match.rank <= 100
          '这是前100个常用密码'
        else
          '这是一个非常常见的密码'
      else if match.guesses_log10 <= 4
        '这类似于常用的密码'
    else if match.dictionary_name == 'english_wikipedia'
      if is_sole_match
        '单词本身很容易猜到'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        '姓名和姓氏本身很容易猜到'
      else
        '常见的名字和姓氏很容易猜到'
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push "大写化并没有多大帮助"
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push "全大写几乎像全小写一样容易猜测"

    if match.reversed and match.token.length >= 4
      suggestions.push "反转单词并不难猜"
    if match.l33t
      suggestions.push "用‘@’替换a这样的可预测替换并没有多大帮助"

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback
