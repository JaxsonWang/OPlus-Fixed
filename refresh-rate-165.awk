# 仅修改刷新率策略；保留版本、温控、相机和亮度相关规则。
function get_attr(tag, name, pattern, value) {
    pattern = "[[:space:]]+" name "[[:space:]]*=[[:space:]]*(\"[^\"]*\"|'[^']*')"
    if (!match(tag, pattern)) return ""
    value = substr(tag, RSTART, RLENGTH)
    sub(/^[^=]*=[[:space:]]*["']/, "", value)
    sub(/["']$/, "", value)
    return value
}

function selectable_rates(value, rates, count, i) {
    if (value == "") return "0-0-0-3-7"
    count = split(value, rates, "-")
    if (count < 4 || count > 5) {
        invalid = 1
        return value
    }
    for (i = 1; i <= count; i++) {
        if (rates[i] !~ /^[0-8]$/) invalid = 1
    }
    # 系统原生菜单：120Hz 使用 mode 3（第四项），165Hz 使用 mode 8（第五项）。
    return rates[1] "-" rates[2] "-" rates[3] "-3-7"
}

function set_attr(tag, name, value, pattern) {
    pattern = "[[:space:]]+" name "[[:space:]]*=[[:space:]]*(\"[^\"]*\"|'[^']*')"
    if (tag ~ pattern) {
        sub(pattern, " " name "=\"" value "\"", tag)
    } else if (tag ~ /\/[[:space:]]*>$/) {
        sub(/[[:space:]]*\/[[:space:]]*>$/, " " name "=\"" value "\" />", tag)
    } else {
        sub(/[[:space:]]*>$/, " " name "=\"" value "\">", tag)
    }
    return tag
}

function process_content(start, finish, tag) {
    while ((start = index(content, "<")) > 0) {
        printf "%s", substr(content, 1, start - 1)
        content = substr(content, start)
        # 注释中的示例不是生效规则，必须完整跳过。
        if (substr(content, 1, 4) == "<!--") {
            finish = index(content, "-->")
            if (!finish) return
            finish += 2
        } else {
            finish = index(content, ">")
            if (!finish) return
        }
        tag = substr(content, 1, finish)
        content = substr(content, finish + 1)
        if (tag ~ /^<refresh_rate_config[[:space:]>]/) roots++
        if (tag == "</refresh_rate_config>") closes++
        if (tag ~ /^<config[[:space:]>]/) {
            configs++
            tag = set_attr(tag, "defaultRateId", selectable_rates(get_attr(tag, "defaultRateId")))
            tag = set_attr(tag, "defaultMaxRate", "120")
            # 不能设为 7，否则旧高刷档和锁屏仍会被统一推到 165Hz。
            tag = set_attr(tag, "maxrefreshsettings", "3")
            tag = set_attr(tag, "disableViewOverrideDefault", "true")
        }
        if (tag ~ /^<item[[:space:]>]/) {
            items++
            tag = set_attr(tag, "rateId", selectable_rates(get_attr(tag, "rateId")))
            if (tag ~ /[[:space:]]secRateId[[:space:]]*=/) {
                tag = set_attr(tag, "secRateId", selectable_rates(get_attr(tag, "secRateId")))
            }
            tag = set_attr(tag, "disableViewOverride", "true")
            tag = set_attr(tag, "enableWinOverride", "false")
            tag = set_attr(tag, "appreqfirst", "false")
        }
        printf "%s", tag
    }
    printf "%s", content
    content = ""
}

{
    # 按行处理完整标签，避免在早期开机阶段反复复制整份应用名单。
    content = content $0 "\n"
    process_content()
}

END {
    if (content != "") exit 1
    if (invalid || roots != 1 || closes != 1 || items == 0 || configs != 1) exit 1
}
