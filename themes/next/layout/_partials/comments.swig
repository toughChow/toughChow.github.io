{% if page.comments %}
  <div class="comments" id="comments"></div>
    {% if (theme.valine and theme.valine.enable)%}
    <script src="//cdn1.lncld.net/static/js/3.0.4/av-min.js"></script>
    <script src="//cdn.jsdelivr.net/npm/valine@1.1.6/dist/Valine.min.js"></script>
    <script>
        new Valine({
            av: AV,
            el: '.comments',
            notify: true, // 邮件提醒 v1.1.4新增，下一步中有具体的邮箱设置
            verify: true,
            app_id: '{{ theme.valine.appId }}',
            app_key: '{{ theme.valine.appKey }}',
            placeholder: 'ヾﾉ≧∀≦)o来啊，快活啊!'
        });
    </script>
    {% endif %}
{% endif %}