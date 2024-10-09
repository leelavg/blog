grep -rlE '\s+:\w+:' content/posts/ | xargs -r sed -ri 's, (:[a-z_]+:), {{e(i="\1")}},g'
