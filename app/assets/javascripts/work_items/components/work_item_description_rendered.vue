<script>
import { GlButton, GlSafeHtmlDirective } from '@gitlab/ui';
import $ from 'jquery';
import '~/behaviors/markdown/render_gfm';

const isCheckbox = (target) => target?.classList.contains('task-list-item-checkbox');

export default {
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  components: {
    GlButton,
  },
  props: {
    workItemDescription: {
      type: Object,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    descriptionText() {
      return this.workItemDescription?.description;
    },
    descriptionHtml() {
      return this.workItemDescription?.descriptionHtml;
    },
    descriptionEmpty() {
      return this.descriptionHtml?.trim() === '';
    },
  },
  watch: {
    descriptionHtml: {
      handler() {
        this.renderGFM();
      },
      immediate: true,
    },
  },
  methods: {
    async renderGFM() {
      await this.$nextTick();

      $(this.$refs['gfm-content']).renderGFM();

      if (this.canEdit) {
        this.checkboxes = this.$el.querySelectorAll('.task-list-item-checkbox');

        // enable boxes, disabled by default in markdown
        this.checkboxes.forEach((checkbox) => {
          // eslint-disable-next-line no-param-reassign
          checkbox.disabled = false;
        });
      }
    },
    toggleCheckboxes(event) {
      const { target } = event;

      if (isCheckbox(target)) {
        target.disabled = true;

        const { sourcepos } = target.parentElement.dataset;

        if (!sourcepos) return;

        const [startRange] = sourcepos.split('-');
        let [startRow] = startRange.split(':');
        startRow = Number(startRow) - 1;

        const descriptionTextRows = this.descriptionText.split('\n');
        const newDescriptionText = descriptionTextRows
          .map((row, index) => {
            if (startRow === index) {
              if (target.checked) {
                return row.replace(/\[ \]/, '[x]');
              }
              return row.replace(/\[[x~]\]/i, '[ ]');
            }
            return row;
          })
          .join('\n');

        this.$emit('descriptionUpdated', newDescriptionText);
      }
    },
  },
};
</script>

<template>
  <div class="gl-mb-5 gl-border-t gl-pt-5">
    <div class="gl-display-inline-flex gl-align-items-center gl-mb-5">
      <label class="d-block col-form-label gl-mr-5">{{ __('Description') }}</label>
      <gl-button
        v-if="canEdit"
        class="gl-ml-auto"
        icon="pencil"
        data-testid="edit-description"
        :aria-label="__('Edit description')"
        @click="$emit('startEditing')"
      />
    </div>

    <div v-if="descriptionEmpty" class="gl-text-secondary gl-mb-5">{{ __('None') }}</div>
    <div
      v-else
      ref="gfm-content"
      v-safe-html="descriptionHtml"
      class="md gl-mb-5 gl-min-h-8"
      @change="toggleCheckboxes"
    ></div>
  </div>
</template>
