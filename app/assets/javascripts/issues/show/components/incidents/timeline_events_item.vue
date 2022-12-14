<script>
import { GlDropdown, GlDropdownItem, GlIcon, GlSafeHtmlDirective, GlSprintf } from '@gitlab/ui';
import { formatDate } from '~/lib/utils/datetime_utility';
import { timelineItemI18n } from './constants';
import { getEventIcon } from './utils';

export default {
  name: 'IncidentTimelineEventListItem',
  i18n: timelineItemI18n,
  components: {
    GlDropdown,
    GlDropdownItem,
    GlIcon,
    GlSprintf,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  inject: ['canUpdateTimelineEvent'],
  props: {
    occurredAt: {
      type: String,
      required: true,
    },
    action: {
      type: String,
      required: true,
    },
    noteHtml: {
      type: String,
      required: true,
    },
  },
  computed: {
    time() {
      return formatDate(this.occurredAt, 'HH:MM', true);
    },
  },
  methods: {
    getEventIcon,
  },
};
</script>
<template>
  <div class="gl-display-flex gl-align-items-start">
    <div
      class="gl-display-flex gl-align-items-center gl-justify-content-center gl-bg-white gl-text-gray-200 gl-border-gray-100 gl-border-1 gl-border-solid gl-rounded-full gl-mt-2 gl-mr-3 gl-w-8 gl-h-8 gl-p-3 gl-z-index-1"
    >
      <gl-icon :name="getEventIcon(action)" class="note-icon" />
    </div>
    <div
      class="timeline-event-note timeline-event-border gl-w-full gl-display-flex gl-flex-direction-row"
      data-testid="event-text-container"
    >
      <div>
        <strong class="gl-font-lg" data-testid="event-time">
          <gl-sprintf :message="$options.i18n.timeUTC">
            <template #time>{{ time }}</template>
          </gl-sprintf>
        </strong>
        <div v-safe-html="noteHtml"></div>
      </div>
      <gl-dropdown
        v-if="canUpdateTimelineEvent"
        right
        class="event-note-actions gl-ml-auto gl-align-self-start"
        icon="ellipsis_v"
        text-sr-only
        :text="$options.i18n.moreActions"
        category="tertiary"
        no-caret
      >
        <gl-dropdown-item @click="$emit('edit')">
          {{ $options.i18n.edit }}
        </gl-dropdown-item>
        <gl-dropdown-item @click="$emit('delete')">
          {{ $options.i18n.delete }}
        </gl-dropdown-item>
      </gl-dropdown>
    </div>
  </div>
</template>
