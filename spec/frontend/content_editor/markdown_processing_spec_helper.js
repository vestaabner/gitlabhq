import fs from 'fs';
import jsYaml from 'js-yaml';
import { memoize } from 'lodash';
import MockAdapter from 'axios-mock-adapter';
import axios from 'axios';
import { createContentEditor } from '~/content_editor';
import httpStatus from '~/lib/utils/http_status';

const getFocusedMarkdownExamples = memoize(
  () => process.env.FOCUSED_MARKDOWN_EXAMPLES?.split(',') || [],
);

const includeExample = ({ name }) => {
  const focusedMarkdownExamples = getFocusedMarkdownExamples();
  if (!focusedMarkdownExamples.length) {
    return true;
  }
  return focusedMarkdownExamples.includes(name);
};

const getPendingReason = (pendingStringOrObject) => {
  if (!pendingStringOrObject) {
    return null;
  }
  if (typeof pendingStringOrObject === 'string') {
    return pendingStringOrObject;
  }
  if (pendingStringOrObject.frontend) {
    return pendingStringOrObject.frontend;
  }

  return null;
};

const loadMarkdownApiExamples = (markdownYamlPath) => {
  const apiMarkdownYamlText = fs.readFileSync(markdownYamlPath);
  const apiMarkdownExampleObjects = jsYaml.safeLoad(apiMarkdownYamlText);

  return apiMarkdownExampleObjects
    .filter(includeExample)
    .map(({ name, pending, markdown, html }) => [
      name,
      { pendingReason: getPendingReason(pending), markdown, html },
    ]);
};

const testSerializesHtmlToMarkdownForElement = async ({ markdown, html }) => {
  const mock = new MockAdapter(axios);

  // Ignore any API requests from the suggestions plugin
  mock.onGet().reply(httpStatus.OK, []);

  const contentEditor = createContentEditor({
    // Overwrite renderMarkdown to always return this specific html
    renderMarkdown: () => html,
  });

  await contentEditor.setSerializedContent(markdown);

  // This serializes the ContentEditor document, which was based on the HTML, to markdown
  const serializedContent = contentEditor.getSerializedContent();

  // Assert that the markdown we ended up with after sending it through all the ContentEditor
  // plumbing matches the original markdown from the YAML.
  expect(serializedContent.trim()).toBe(markdown.trim());

  mock.restore();
};

// describeMarkdownProcesssing
//
// This is used to dynamically generate examples (for both CE and EE) to ensure
// we generate same markdown that was provided to Markdown API.
//
// eslint-disable-next-line jest/no-export
export const describeMarkdownProcessing = (description, markdownYamlPath) => {
  const examples = loadMarkdownApiExamples(markdownYamlPath);

  describe(description, () => {
    describe.each(examples)('%s', (name, { pendingReason, ...example }) => {
      const exampleName = 'correctly serializes HTML to markdown';
      if (pendingReason) {
        it.todo(`${exampleName}: ${pendingReason}`);
        return;
      }

      it(`${exampleName}`, async () => {
        await testSerializesHtmlToMarkdownForElement(example);
      });
    });
  });
};
